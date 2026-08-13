import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_health_log.dart';
import '../services/database_service.dart';

enum HealthConnectionStatus { unknown, notInstalled, notAuthorized, authorized }

class HealthProvider extends ChangeNotifier {
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  final Health _health = Health();
  final DatabaseService _db = DatabaseService.instance;

  HealthConnectionStatus status = HealthConnectionStatus.unknown;
  bool isSyncing = false;
  String? errorMessage;
  DateTime? lastSynced;

  int? steps;
  double? heartRate;
  int? sleepMinutes;
  double? caloriesBurned;

  /// Trailing daily-step baseline (previous 7 full days, zero-step days
  /// excluded) and the personalized target derived from it — replaces a
  /// one-size-fits-all 10,000-step goal with one based on the user's own
  /// recent activity, gently nudged upward.
  double? averageDailySteps;
  int? stepGoal;

  String get sleepLabel {
    final m = sleepMinutes;
    if (m == null) return '--';
    return '${m ~/ 60}h ${m % 60}m';
  }

  /// A modest (+10%) stretch above the recent daily average, rounded to a
  /// friendly number and bounded to a sane range. Pure/static so it's easy
  /// to unit test without a live Health Connect connection.
  static int personalizedStepTarget(double trailingAverageSteps) {
    final target = ((trailingAverageSteps * 1.1) / 100).round() * 100;
    return target.clamp(3000, 20000);
  }

  Future<void> init() async {
    if (!Platform.isAndroid) {
      status = HealthConnectionStatus.notInstalled;
      notifyListeners();
      return;
    }
    await _health.configure();
    await _loadCache();

    final available = await _health.isHealthConnectAvailable();
    if (!available) {
      status = HealthConnectionStatus.notInstalled;
      notifyListeners();
      return;
    }

    final granted = await _health.hasPermissions(_types) ?? false;
    status = granted ? HealthConnectionStatus.authorized : HealthConnectionStatus.notAuthorized;
    notifyListeners();

    if (granted) await syncNow();
  }

  Future<void> connect() async {
    if (!Platform.isAndroid) return;

    final available = await _health.isHealthConnectAvailable();
    if (!available) {
      status = HealthConnectionStatus.notInstalled;
      notifyListeners();
      await _health.installHealthConnect();
      return;
    }

    await Permission.activityRecognition.request();

    final granted = await _health.requestAuthorization(_types);
    status = granted ? HealthConnectionStatus.authorized : HealthConnectionStatus.notAuthorized;
    notifyListeners();

    if (granted) await syncNow();
  }

  Future<void> syncNow() async {
    if (status != HealthConnectionStatus.authorized || isSyncing) return;

    isSyncing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sleepWindowStart = startOfDay.subtract(const Duration(hours: 12));

      final stepsResult = await _health.getTotalStepsInInterval(startOfDay, now);

      final heartRatePoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );
      double? avgHeartRate;
      if (heartRatePoints.isNotEmpty) {
        final values = heartRatePoints
            .map((p) => p.value)
            .whereType<NumericHealthValue>()
            .map((v) => v.numericValue.toDouble())
            .toList();
        if (values.isNotEmpty) {
          avgHeartRate = values.reduce((a, b) => a + b) / values.length;
        }
      }

      final sleepPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: sleepWindowStart,
        endTime: now,
      );
      final sleepMins = sleepPoints.fold<int>(
        0,
        (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes,
      );

      // Prefer TOTAL_CALORIES_BURNED (includes BMR), but some watches/apps
      // (Zepp included) only sync active/exercise calories to Health Connect,
      // so fall back to ACTIVE_ENERGY_BURNED when total isn't populated.
      double? sumCalories(List<HealthDataPoint> points) {
        final values = points.map((p) => p.value).whereType<NumericHealthValue>().map((v) => v.numericValue.toDouble());
        return values.isEmpty ? null : values.reduce((a, b) => a + b);
      }

      final totalCaloriePoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
        startTime: startOfDay,
        endTime: now,
      );
      var totalCalories = sumCalories(totalCaloriePoints);
      if (totalCalories == null) {
        final activeCaloriePoints = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startOfDay,
          endTime: now,
        );
        totalCalories = sumCalories(activeCaloriePoints);
      }

      steps = stepsResult;
      heartRate = avgHeartRate;
      sleepMinutes = sleepPoints.isEmpty ? null : sleepMins;
      caloriesBurned = totalCalories;
      lastSynced = now;

      final trailingAvg = await _fetchTrailingAverageSteps(startOfDay);
      if (trailingAvg != null) {
        averageDailySteps = trailingAvg;
        stepGoal = personalizedStepTarget(trailingAvg);
      }

      await _saveCache();
      // Record today's snapshot into history — this is what lets pattern/
      // trend features look back further than just "today".
      if (steps != null || sleepMinutes != null) {
        await _db.upsertDailyHealthLog(DailyHealthLog(date: startOfDay, steps: steps, sleepMinutes: sleepMinutes));
      }
    } catch (e) {
      errorMessage = 'Sync failed: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  /// Averages total steps over the 7 full days before [today], skipping any
  /// day with zero steps (almost always a sync gap, not genuinely zero
  /// activity, and would otherwise drag the baseline down misleadingly).
  /// Returns null if there isn't at least one day of data.
  Future<double?> _fetchTrailingAverageSteps(DateTime today) async {
    final dailyTotals = <int>[];
    for (var i = 1; i <= 7; i++) {
      final dayStart = today.subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final total = await _health.getTotalStepsInInterval(dayStart, dayEnd);
      if (total != null && total > 0) dailyTotals.add(total);
    }
    if (dailyTotals.isEmpty) return null;
    return dailyTotals.reduce((a, b) => a + b) / dailyTotals.length;
  }

  /// Full recorded daily-history — newest first. Used by trend/pattern
  /// features; the live fields above (`steps`, `sleepMinutes`, …) remain
  /// the fast path for "today".
  Future<List<DailyHealthLog>> history() => _db.getAllDailyHealthLogs();

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    steps = prefs.getInt('health_steps');
    final hr = prefs.getDouble('health_heart_rate');
    heartRate = hr;
    sleepMinutes = prefs.getInt('health_sleep_minutes');
    caloriesBurned = prefs.getDouble('health_calories');
    averageDailySteps = prefs.getDouble('health_avg_daily_steps');
    stepGoal = prefs.getInt('health_step_goal');
    final lastSyncedMs = prefs.getInt('health_last_synced');
    lastSynced = lastSyncedMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncedMs) : null;
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (steps != null) await prefs.setInt('health_steps', steps!);
    if (heartRate != null) await prefs.setDouble('health_heart_rate', heartRate!);
    if (sleepMinutes != null) await prefs.setInt('health_sleep_minutes', sleepMinutes!);
    if (caloriesBurned != null) await prefs.setDouble('health_calories', caloriesBurned!);
    if (averageDailySteps != null) await prefs.setDouble('health_avg_daily_steps', averageDailySteps!);
    if (stepGoal != null) await prefs.setInt('health_step_goal', stepGoal!);
    if (lastSynced != null) await prefs.setInt('health_last_synced', lastSynced!.millisecondsSinceEpoch);
  }
}
