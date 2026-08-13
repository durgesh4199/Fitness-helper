import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/water_log.dart';
import 'package:fitness_tracker/models/weight_log.dart';
import 'package:fitness_tracker/services/database_service.dart';

/// Covers the v5 migration additions (weight_logs / water_logs) directly
/// against the database layer, including the bulk clear-and-insert methods
/// backup restore relies on.
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
}
