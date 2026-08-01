import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HealthConnectionStatus { unknown, notInstalled, notAuthorized, authorized }

class HealthProvider extends ChangeNotifier {
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  final Health _health = Health();

  HealthConnectionStatus status = HealthConnectionStatus.unknown;
  bool isSyncing = false;
  String? errorMessage;
  DateTime? lastSynced;

  int? steps;
  double? heartRate;
  int? sleepMinutes;
  double? caloriesBurned;

  String get sleepLabel {
    final m = sleepMinutes;
    if (m == null) return '--';
    return '${m ~/ 60}h ${m % 60}m';
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

      final caloriePoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
        startTime: startOfDay,
        endTime: now,
      );
      final calorieValues = caloriePoints
          .map((p) => p.value)
          .whereType<NumericHealthValue>()
          .map((v) => v.numericValue.toDouble());
      final totalCalories = calorieValues.isEmpty ? null : calorieValues.reduce((a, b) => a + b);

      steps = stepsResult;
      heartRate = avgHeartRate;
      sleepMinutes = sleepPoints.isEmpty ? null : sleepMins;
      caloriesBurned = totalCalories;
      lastSynced = now;
      await _saveCache();
    } catch (e) {
      errorMessage = 'Sync failed: $e';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    steps = prefs.getInt('health_steps');
    final hr = prefs.getDouble('health_heart_rate');
    heartRate = hr;
    sleepMinutes = prefs.getInt('health_sleep_minutes');
    caloriesBurned = prefs.getDouble('health_calories');
    final lastSyncedMs = prefs.getInt('health_last_synced');
    lastSynced = lastSyncedMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncedMs) : null;
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (steps != null) await prefs.setInt('health_steps', steps!);
    if (heartRate != null) await prefs.setDouble('health_heart_rate', heartRate!);
    if (sleepMinutes != null) await prefs.setInt('health_sleep_minutes', sleepMinutes!);
    if (caloriesBurned != null) await prefs.setDouble('health_calories', caloriesBurned!);
    if (lastSynced != null) await prefs.setInt('health_last_synced', lastSynced!.millisecondsSinceEpoch);
  }
}
