import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/providers/weight_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late WeightProvider provider;

  setUp(() async {
    provider = WeightProvider();
    await provider.load();
    for (final log in List.of(provider.logs)) {
      if (log.id != null) await provider.deleteEntry(log.id!);
    }
  });

  test('averages/changes are null with no entries', () {
    expect(provider.averageOverDays(7), isNull);
    expect(provider.weeklyChange, isNull);
    expect(provider.currentWeightKg, isNull);
  });

  test('sevenDayAverage only includes entries within the window', () async {
    final now = DateTime.now();
    await provider.addEntry(weightKg: 70, dateTime: now.subtract(const Duration(days: 2)));
    await provider.addEntry(weightKg: 72, dateTime: now.subtract(const Duration(days: 20)));

    expect(provider.sevenDayAverage, closeTo(70, 0.01));
  });

  test('weeklyChange compares latest to the entry closest to 7 days ago', () async {
    final now = DateTime.now();
    await provider.addEntry(weightKg: 75, dateTime: now.subtract(const Duration(days: 8)));
    await provider.addEntry(weightKg: 73, dateTime: now);

    expect(provider.weeklyChange, closeTo(-2, 0.01));
  });

  test('progressToward measures fraction of the goal reached from the earliest entry', () async {
    final now = DateTime.now();
    await provider.addEntry(weightKg: 80, dateTime: now.subtract(const Duration(days: 30)));
    await provider.addEntry(weightKg: 75, dateTime: now);

    // Started at 80kg, now at 75kg, goal is 70kg -> halfway there.
    expect(provider.progressToward(70), closeTo(0.5, 0.01));
  });

  test('deleteEntry removes the entry', () async {
    final now = DateTime.now();
    await provider.addEntry(weightKg: 68, dateTime: now);
    final id = provider.logs.first.id!;

    await provider.deleteEntry(id);

    expect(provider.logs.where((l) => l.id == id), isEmpty);
  });
}
