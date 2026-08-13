import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/body_measurement_log.dart';
import 'package:fitness_tracker/models/water_log.dart';
import 'package:fitness_tracker/models/weight_log.dart';
import 'package:fitness_tracker/models/workout_log.dart';
import 'package:fitness_tracker/services/database_service.dart';

/// Covers the v5/v6 migration additions (weight_logs / water_logs /
/// body_measurement_logs / workout_logs.rpe) directly against the database
/// layer, including the bulk clear-and-insert methods backup restore relies
/// on.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final db = DatabaseService.instance;

  setUp(() async {
    for (final w in await db.getAllWeightLogs()) {
      if (w.id != null) await db.deleteWeightLog(w.id!);
    }
    for (final w in await db.getAllWaterLogs()) {
      if (w.id != null) await db.deleteWaterLog(w.id!);
    }
    for (final b in await db.getAllBodyMeasurementLogs()) {
      if (b.id != null) await db.deleteBodyMeasurementLog(b.id!);
    }
    for (final l in await db.getAllLogs()) {
      if (l.id != null) await db.deleteLog(l.id!);
    }
  });

  test('weight log insert/read round-trip, defaulting source to userEntered', () async {
    final id = await db.insertWeightLog(WeightLog(weight: 68.5, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllWeightLogs();

    expect(all.length, 1);
    expect(all.first.id, id);
    expect(all.first.weight, 68.5);
    expect(all.first.source.name, 'userEntered');
  });

  test('clearAndInsertWeightLogs replaces existing rows (backup restore path)', () async {
    await db.insertWeightLog(WeightLog(weight: 60, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertWeightLogs([
      WeightLog(weight: 70, dateTime: DateTime(2026, 2, 1)),
      WeightLog(weight: 71, dateTime: DateTime(2026, 2, 2)),
    ]);

    final all = await db.getAllWeightLogs();
    expect(all.length, 2);
    expect(all.map((w) => w.weight), containsAll(<double>[70, 71]));
  });

  test('water log insert/read round-trip', () async {
    await db.insertWaterLog(WaterLog(amountMl: 250, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllWaterLogs();
    expect(all.length, 1);
    expect(all.first.amountMl, 250);
  });

  test('clearAndInsertWaterLogs replaces existing rows (backup restore path)', () async {
    await db.insertWaterLog(WaterLog(amountMl: 100, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertWaterLogs([
      WaterLog(amountMl: 250, dateTime: DateTime(2026, 2, 1)),
      WaterLog(amountMl: 500, dateTime: DateTime(2026, 2, 2)),
    ]);

    final all = await db.getAllWaterLogs();
    expect(all.length, 2);
    expect(all.map((w) => w.amountMl), containsAll(<int>[250, 500]));
  });

  test('body measurement log insert/read round-trip (waist only)', () async {
    await db.insertBodyMeasurementLog(BodyMeasurementLog(waistCm: 84.5, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllBodyMeasurementLogs();
    expect(all.length, 1);
    expect(all.first.waistCm, 84.5);
    expect(all.first.neckCm, isNull);
  });

  test('clearAndInsertBodyMeasurementLogs replaces existing rows (backup restore path)', () async {
    await db.insertBodyMeasurementLog(BodyMeasurementLog(waistCm: 90, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertBodyMeasurementLogs([
      BodyMeasurementLog(waistCm: 85, dateTime: DateTime(2026, 2, 1)),
      BodyMeasurementLog(waistCm: 84, dateTime: DateTime(2026, 2, 2)),
    ]);

    final all = await db.getAllBodyMeasurementLogs();
    expect(all.length, 2);
    expect(all.map((b) => b.waistCm), containsAll(<double>[85, 84]));
  });

  test('workout log persists rpe alongside existing fields', () async {
    await db.insertLog(WorkoutLog(title: 'Run', category: 'Cardio', minutes: 30, calories: 250, dateTime: DateTime(2026, 1, 1), rpe: 7));

    final all = await db.getAllLogs();
    expect(all.length, 1);
    expect(all.first.rpe, 7);
    expect(all.first.trainingLoad, 210);
  });

  test('workout log without rpe still round-trips (pre-v6 shape stays valid)', () async {
    await db.insertLog(WorkoutLog(title: 'Walk', category: 'Cardio', minutes: 20, calories: 90, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllLogs();
    expect(all.first.rpe, isNull);
  });
}
