import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/providers/body_measurement_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late BodyMeasurementProvider provider;

  setUp(() async {
    provider = BodyMeasurementProvider();
    await provider.load();
    for (final log in List.of(provider.logs)) {
      if (log.id != null) await provider.deleteEntry(log.id!);
    }
  });

  test('no entries -> null waist stats', () {
    expect(provider.currentWaistCm, isNull);
    expect(provider.waistWeeklyChange, isNull);
  });

  test('addEntry stores waist and keeps entries newest-first', () async {
    final now = DateTime.now();
    await provider.addEntry(waistCm: 86, dateTime: now.subtract(const Duration(days: 3)));
    await provider.addEntry(waistCm: 84, dateTime: now);

    expect(provider.currentWaistCm, 84);
    expect(provider.logs.first.waistCm, 84);
    expect(provider.logs.last.waistCm, 86);
  });

  test('waistWeeklyChange compares latest to the entry closest to 7 days ago', () async {
    final now = DateTime.now();
    await provider.addEntry(waistCm: 90, dateTime: now.subtract(const Duration(days: 8)));
    await provider.addEntry(waistCm: 87, dateTime: now);

    expect(provider.waistWeeklyChange, closeTo(-3, 0.01));
  });

  test('entries without a waist value are ignored by waist stats', () async {
    final now = DateTime.now();
    await provider.addEntry(waistCm: 85, dateTime: now.subtract(const Duration(days: 5)));
    await provider.addEntry(neckCm: 38, dateTime: now); // no waist on this one

    expect(provider.currentWaistCm, 85);
  });

  test('deleteEntry removes the entry', () async {
    final now = DateTime.now();
    await provider.addEntry(waistCm: 82, dateTime: now);
    final id = provider.logs.first.id!;

    await provider.deleteEntry(id);

    expect(provider.logs.where((l) => l.id == id), isEmpty);
  });
}
