import 'package:flutter/material.dart';
import '../models/body_measurement_log.dart';
import '../services/database_service.dart';

/// Historical body measurements (waist, and optionally neck/chest/arms/
/// thighs/hips). Mirrors [WeightProvider]'s shape.
class BodyMeasurementProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  /// Newest first.
  List<BodyMeasurementLog> _logs = [];
  bool _loading = true;

  List<BodyMeasurementLog> get logs => _logs;
  bool get loading => _loading;

  BodyMeasurementLog? get latest => _logs.isEmpty ? null : _logs.first;

  /// The most recent entry that actually has a waist value — not
  /// necessarily [latest], since an entry might log other measurements
  /// without waist.
  double? get currentWaistCm {
    for (final l in _logs) {
      if (l.waistCm != null) return l.waistCm;
    }
    return null;
  }

  Future<void> load() async {
    _logs = await _db.getAllBodyMeasurementLogs();
    _loading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    DateTime? dateTime,
    double? waistCm,
    double? neckCm,
    double? chestCm,
    double? armsCm,
    double? thighsCm,
    double? hipsCm,
    String? notes,
  }) async {
    final log = BodyMeasurementLog(
      dateTime: dateTime ?? DateTime.now(),
      waistCm: waistCm,
      neckCm: neckCm,
      chestCm: chestCm,
      armsCm: armsCm,
      thighsCm: thighsCm,
      hipsCm: hipsCm,
      notes: notes,
    );
    final id = await _db.insertBodyMeasurementLog(log);
    _logs = [log.copyWith(id: id), ..._logs]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteBodyMeasurementLog(id);
    _logs = _logs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  /// Replaces all body measurement logs with [logs] — used when restoring a
  /// backup.
  Future<void> restoreLogs(List<BodyMeasurementLog> logs) async {
    await _db.clearAndInsertBodyMeasurementLogs(logs);
    await load();
  }

  /// Change in waist measurement between the latest entry and the one
  /// closest to (but not after) [days] ago. Null without enough history.
  double? waistChangeOverDays(int days) {
    final withWaist = _logs.where((l) => l.waistCm != null).toList();
    if (withWaist.length < 2) return null;
    final current = withWaist.first;

    final target = DateTime.now().subtract(Duration(days: days));
    BodyMeasurementLog? reference;
    for (final l in withWaist.reversed) {
      if (!l.dateTime.isAfter(target)) reference = l;
    }
    reference ??= withWaist.last;
    if (reference.id == current.id) return null;
    return current.waistCm! - reference.waistCm!;
  }

  double? get waistWeeklyChange => waistChangeOverDays(7);
}
