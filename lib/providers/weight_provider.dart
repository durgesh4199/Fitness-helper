import 'package:flutter/material.dart';
import '../models/health_data_source.dart';
import '../models/weight_log.dart';
import '../services/database_service.dart';

/// Historical weight tracking. Kept separate from [UserProvider], which only
/// holds the single "current weight" used for BMI/calorie calculations —
/// this provider is what backs trends, averages, and the weight chart.
class WeightProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  /// Newest first (matches the `date_time DESC` query).
  List<WeightLog> _logs = [];
  bool _loading = true;

  List<WeightLog> get logs => _logs;
  bool get loading => _loading;

  WeightLog? get latest => _logs.isEmpty ? null : _logs.first;
  double? get currentWeightKg => latest?.weight;

  Future<void> load() async {
    _logs = await _db.getAllWeightLogs();
    _loading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    required double weightKg,
    double? bodyFat,
    DateTime? dateTime,
    String? notes,
    HealthDataSource source = HealthDataSource.userEntered,
  }) async {
    final log = WeightLog(
      weight: weightKg,
      bodyFat: bodyFat,
      dateTime: dateTime ?? DateTime.now(),
      source: source,
      notes: notes,
    );
    final id = await _db.insertWeightLog(log);
    _logs = [log.copyWith(id: id), ..._logs]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteWeightLog(id);
    _logs = _logs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  /// Replaces all weight logs with [logs] — used when restoring a backup.
  Future<void> restoreLogs(List<WeightLog> logs) async {
    await _db.clearAndInsertWeightLogs(logs);
    await load();
  }

  /// Average weight over the last [days] days, or null if there's no entry
  /// in that window. A rolling average smooths out normal day-to-day water-
  /// weight swings so a single heavy or light day doesn't look like a trend.
  double? averageOverDays(int days) {
    if (_logs.isEmpty) return null;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final within = _logs.where((l) => l.dateTime.isAfter(cutoff)).toList();
    if (within.isEmpty) return null;
    return within.map((l) => l.weight).reduce((a, b) => a + b) / within.length;
  }

  double? get sevenDayAverage => averageOverDays(7);
  double? get thirtyDayAverage => averageOverDays(30);

  /// Change in weight over the last [days] days: latest entry minus the
  /// entry closest to (but not after) `days` ago. Null if there isn't at
  /// least one entry old enough to compare against.
  double? changeOverDays(int days) {
    final current = latest;
    if (current == null || _logs.length < 2) return null;

    final target = DateTime.now().subtract(Duration(days: days));
    WeightLog? reference;
    // _logs is newest-first; walk from the oldest end looking for the first
    // entry at or before the target date.
    for (final l in _logs.reversed) {
      if (!l.dateTime.isAfter(target)) reference = l;
    }
    reference ??= _logs.last; // no entry old enough — fall back to the earliest
    if (reference.id == current.id) return null;
    return current.weight - reference.weight;
  }

  double? get weeklyChange => changeOverDays(7);
  double? get monthlyChange => changeOverDays(30);

  /// Progress toward [goalWeightKg], using the earliest logged entry as the
  /// starting point. 1.0 = fully there, 0.0 = no progress yet. Not clamped
  /// to 1.0 on the high side so overshoot is still visible.
  double? progressToward(double goalWeightKg) {
    if (_logs.isEmpty) return null;
    final start = _logs.last.weight; // oldest entry
    final current = _logs.first.weight; // newest entry
    final totalDelta = goalWeightKg - start;
    if (totalDelta.abs() < 0.01) return 1.0;
    return ((current - start) / totalDelta).clamp(0.0, 1.5);
  }
}
