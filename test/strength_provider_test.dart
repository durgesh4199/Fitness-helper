import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/strength_progress.dart';
import 'package:fitness_tracker/models/strength_set.dart';
import 'package:fitness_tracker/providers/strength_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late StrengthProvider provider;

  setUp(() async {
    provider = StrengthProvider();
    await provider.load();
    for (final s in List.of(provider.sets)) {
      if (s.id != null) await provider.deleteSet(s.id!);
    }
  });

  test('addSet persists and returns the saved set with an id', () async {
    final saved = await provider.addSet(StrengthSet(
      workoutLogId: 1,
      exerciseName: 'Squat',
      setIndex: 1,
      reps: 5,
      weightKg: 80,
      dateTime: DateTime.now(),
    ));

    expect(saved.id, isNotNull);
    expect(provider.sets, hasLength(1));
  });

  test('setsForWorkout filters to one workout and orders by set index', () async {
    final now = DateTime.now();
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 2, reps: 5, weightKg: 90, dateTime: now));
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 80, dateTime: now));
    await provider.addSet(StrengthSet(workoutLogId: 2, exerciseName: 'Bench Press', setIndex: 1, reps: 8, weightKg: 50, dateTime: now));

    final sets = provider.setsForWorkout(1);
    expect(sets.map((s) => s.setIndex).toList(), [1, 2]);
  });

  test('deleteSetsForWorkout removes only the matching workout\'s sets from memory', () async {
    final now = DateTime.now();
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 80, dateTime: now));
    await provider.addSet(StrengthSet(workoutLogId: 2, exerciseName: 'Bench Press', setIndex: 1, reps: 8, weightKg: 50, dateTime: now));

    await provider.deleteSetsForWorkout(1);

    expect(provider.sets, hasLength(1));
    expect(provider.sets.first.workoutLogId, 2);
  });

  test('knownExerciseNames lists distinct names, most-recently-logged first', () async {
    final now = DateTime.now();
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 80, dateTime: now));
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 2, reps: 5, weightKg: 80, dateTime: now));
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Bench Press', setIndex: 3, reps: 8, weightKg: 50, dateTime: now));

    expect(provider.knownExerciseNames, ['Bench Press', 'Squat']);
  });

  test('progress delegates to ProgressiveOverloadEngine using all logged sets', () async {
    await provider.addSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 80, dateTime: DateTime(2026, 1, 1)));
    await provider.addSet(StrengthSet(workoutLogId: 2, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 90, dateTime: DateTime(2026, 1, 8)));

    final progress = provider.progress;
    expect(progress, hasLength(1));
    expect(progress.first.trend, ProgressTrend.up);
  });
}
