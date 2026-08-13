import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/workout_log.dart';
import 'package:fitness_tracker/providers/workout_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WorkoutLog.trainingLoad', () {
    test('minutes x rpe computes correctly', () {
      final now = DateTime.now();
      final log = WorkoutLog(title: 'Run', category: 'Cardio', minutes: 30, calories: 250, dateTime: now, rpe: 7);
      expect(log.trainingLoad, 210);
    });

    test('is null without an rpe', () {
      final now = DateTime.now();
      final log = WorkoutLog(title: 'Walk', category: 'Cardio', minutes: 20, calories: 90, dateTime: now);
      expect(log.rpe, isNull);
      expect(log.trainingLoad, isNull);
    });

    test('round-trips through toMap/fromMap', () {
      final now = DateTime.now();
      final log = WorkoutLog(title: 'Lift', category: 'Strength', minutes: 45, calories: 300, dateTime: now, rpe: 8);
      final restored = WorkoutLog.fromMap(log.toMap());
      expect(restored.rpe, 8);
      expect(restored.trainingLoad, 360);
    });
  });

  group('WorkoutProvider.weekTrainingLoad', () {
    late WorkoutProvider provider;

    setUp(() async {
      provider = WorkoutProvider();
      await provider.load();
      for (final log in List.of(provider.logs)) {
        if (log.id != null) await provider.deleteLog(log.id!);
      }
    });

    test('null when nothing this week has an rpe', () async {
      await provider.addLog(WorkoutLog(title: 'Walk', category: 'Cardio', minutes: 20, calories: 90, dateTime: DateTime.now()));
      expect(provider.weekTrainingLoad, isNull);
    });

    test('sums training load only across rated logs', () async {
      final now = DateTime.now();
      await provider.addLog(WorkoutLog(title: 'Run', category: 'Cardio', minutes: 30, calories: 250, dateTime: now, rpe: 6));
      await provider.addLog(WorkoutLog(title: 'Yoga', category: 'Yoga', minutes: 40, calories: 120, dateTime: now)); // no rpe
      await provider.addLog(WorkoutLog(title: 'Lift', category: 'Strength', minutes: 45, calories: 300, dateTime: now, rpe: 8));

      expect(provider.weekTrainingLoad, 30 * 6 + 45 * 8);
    });
  });
}
