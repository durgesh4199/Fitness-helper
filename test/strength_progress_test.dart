import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/strength_progress.dart';
import 'package:fitness_tracker/models/strength_set.dart';

StrengthSet _set(DateTime day, {required String exercise, required int reps, double? weightKg, int setIndex = 1}) {
  return StrengthSet(workoutLogId: 1, exerciseName: exercise, setIndex: setIndex, reps: reps, weightKg: weightKg, dateTime: day);
}

void main() {
  group('StrengthSet.estimated1Rm', () {
    test('equals the weight itself for a single rep', () {
      final set = _set(DateTime(2026, 1, 1), exercise: 'Squat', reps: 1, weightKg: 100);
      expect(set.estimated1Rm, 100);
    });

    test('uses the Epley formula for multiple reps', () {
      final set = _set(DateTime(2026, 1, 1), exercise: 'Squat', reps: 10, weightKg: 60);
      expect(set.estimated1Rm, closeTo(60 * (1 + 10 / 30.0), 0.001));
    });

    test('is null for a bodyweight set (no weight recorded)', () {
      final set = _set(DateTime(2026, 1, 1), exercise: 'Push-up', reps: 15, weightKg: null);
      expect(set.estimated1Rm, isNull);
    });
  });

  group('ProgressiveOverloadEngine.evaluate', () {
    test('says nothing for an exercise with only one session logged', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Bench Press', reps: 8, weightKg: 50),
      ];
      expect(ProgressiveOverloadEngine.evaluate(sets), isEmpty);
    });

    test('detects an upward trend from a clearly heavier top set', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Bench Press', reps: 8, weightKg: 50),
        _set(DateTime(2026, 1, 8), exercise: 'Bench Press', reps: 8, weightKg: 60),
      ];
      final results = ProgressiveOverloadEngine.evaluate(sets);
      expect(results, hasLength(1));
      expect(results.first.trend, ProgressTrend.up);
      expect(results.first.exerciseName, 'Bench Press');
    });

    test('detects a downward trend from a clearly lighter top set', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Deadlift', reps: 5, weightKg: 100),
        _set(DateTime(2026, 1, 8), exercise: 'Deadlift', reps: 5, weightKg: 80),
      ];
      final results = ProgressiveOverloadEngine.evaluate(sets);
      expect(results.first.trend, ProgressTrend.down);
    });

    test('treats a negligible change as flat, not up or down', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Overhead Press', reps: 8, weightKg: 40),
        _set(DateTime(2026, 1, 8), exercise: 'Overhead Press', reps: 8, weightKg: 40.5),
      ];
      final results = ProgressiveOverloadEngine.evaluate(sets);
      expect(results.first.trend, ProgressTrend.flat);
    });

    test('picks the best set of each session, not just the last one logged', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Squat', reps: 5, weightKg: 80, setIndex: 1),
        _set(DateTime(2026, 1, 1), exercise: 'Squat', reps: 5, weightKg: 90, setIndex: 2), // top set of session 1
        _set(DateTime(2026, 1, 8), exercise: 'Squat', reps: 5, weightKg: 85, setIndex: 1),
      ];
      final results = ProgressiveOverloadEngine.evaluate(sets);
      // 85 vs top-of-90 is a decrease, not an increase.
      expect(results.first.trend, ProgressTrend.down);
    });

    test('ignores bodyweight-only sets when there is no weight to compare', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Pull-up', reps: 10, weightKg: null),
        _set(DateTime(2026, 1, 8), exercise: 'Pull-up', reps: 12, weightKg: null),
      ];
      expect(ProgressiveOverloadEngine.evaluate(sets), isEmpty);
    });

    test('tracks multiple exercises independently, sorted by name', () {
      final sets = [
        _set(DateTime(2026, 1, 1), exercise: 'Squat', reps: 5, weightKg: 80),
        _set(DateTime(2026, 1, 8), exercise: 'Squat', reps: 5, weightKg: 90),
        _set(DateTime(2026, 1, 1), exercise: 'Bench Press', reps: 8, weightKg: 50),
        _set(DateTime(2026, 1, 8), exercise: 'Bench Press', reps: 8, weightKg: 50),
      ];
      final results = ProgressiveOverloadEngine.evaluate(sets);
      expect(results.map((r) => r.exerciseName).toList(), ['Bench Press', 'Squat']);
    });
  });
}
