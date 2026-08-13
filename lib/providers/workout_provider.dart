import 'package:flutter/material.dart';
import '../models/recovery_signal.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../services/database_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<WorkoutLog> _logs = [];
  bool _loading = true;

  /// 0 = this week, -1 = last week, -2 = two weeks ago, etc. Browsed on the
  /// Progress screen; never allowed to go past the current week.
  int _weekOffset = 0;

  List<WorkoutLog> get logs => _logs;
  bool get loading => _loading;
  int get weekOffset => _weekOffset;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<WorkoutLog> get todayLogs {
    final now = DateTime.now();
    return _logs.where((l) => _isSameDay(l.dateTime, now)).toList();
  }

  int get todayCalories => todayLogs.fold(0, (sum, l) => sum + l.calories);
  int get todayMinutes => todayLogs.fold(0, (sum, l) => sum + l.minutes);

  /// Monday of the currently browsed week (respects [weekOffset]).
  DateTime get weekStartDate {
    final now = DateTime.now().add(Duration(days: _weekOffset * 7));
    final start = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  void shiftWeek(int delta) {
    final next = _weekOffset + delta;
    _weekOffset = next > 0 ? 0 : next; // never browse into future weeks
    notifyListeners();
  }

  void resetToCurrentWeek() {
    if (_weekOffset == 0) return;
    _weekOffset = 0;
    notifyListeners();
  }

  List<WorkoutLog> get _weekLogs {
    final start = weekStartDate;
    final end = weekStartDate.add(const Duration(days: 7));
    return _logs.where((l) => !l.dateTime.isBefore(start) && l.dateTime.isBefore(end)).toList();
  }

  int get weekWorkoutCount => _weekLogs.length;
  int get weekCalories => _weekLogs.fold(0, (sum, l) => sum + l.calories);
  int get weekMinutes => _weekLogs.fold(0, (sum, l) => sum + l.minutes);

  /// Sum of duration x RPE across the week's logs that have an RPE — a
  /// simple relative training-load number, not a medical assessment. Null
  /// if nothing this week has an RPE yet.
  int? get weekTrainingLoad {
    final rated = _weekLogs.where((l) => l.rpe != null);
    if (rated.isEmpty) return null;
    return rated.fold<int>(0, (sum, l) => sum + l.trainingLoad!);
  }

  /// Consecutive days (ending today or yesterday) with at least one workout.
  int get streakDays {
    if (_logs.isEmpty) return 0;
    final days = _logs.map((l) => DateTime(l.dateTime.year, l.dateTime.month, l.dateTime.day)).toSet();
    var cursor = DateTime.now();
    var cursorDay = DateTime(cursor.year, cursor.month, cursor.day);
    if (!days.contains(cursorDay)) {
      cursorDay = cursorDay.subtract(const Duration(days: 1));
      if (!days.contains(cursorDay)) return 0;
    }
    int streak = 0;
    while (days.contains(cursorDay)) {
      streak++;
      cursorDay = cursorDay.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Minutes trained per day for the currently browsed week (Mon..Sun).
  List<DailyActivity> get weeklyActivity {
    final weekStart = weekStartDate;
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final minutesByDay = List<int>.filled(7, 0);

    for (final log in _weekLogs) {
      final diff = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day)
          .difference(weekStart)
          .inDays;
      if (diff >= 0 && diff < 7) {
        minutesByDay[diff] += log.minutes;
      }
    }

    final maxMinutes = minutesByDay.fold(0, (m, v) => v > m ? v : m);
    return List.generate(7, (i) {
      final value = maxMinutes == 0 ? 0.0 : minutesByDay[i] / maxMinutes;
      return DailyActivity(label: labels[i], value: value);
    });
  }

  Future<void> load() async {
    _logs = await _db.getAllLogs();
    _loading = false;
    notifyListeners();
  }

  Future<int> addLog(WorkoutLog log) async {
    final id = await _db.insertLog(log);
    _logs = [log.copyWith(id: id), ..._logs];
    notifyListeners();
    return id;
  }

  /// Simple heuristic nudge based on training streak + recent RPE — see
  /// [RecoveryAdvisor] for the thresholds and disclaimer. Null most of the
  /// time; only appears when both signals line up.
  RecoverySignal? get recoverySignal => RecoveryAdvisor.evaluate(_logs, streakDays: streakDays);

  Future<void> deleteLog(int id) async {
    await _db.deleteLog(id);
    _logs = _logs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  /// Replaces all workout logs with [logs] — used when restoring a backup.
  Future<void> restoreLogs(List<WorkoutLog> logs) async {
    await _db.clearAndInsertWorkoutLogs(logs);
    await load();
  }
}
