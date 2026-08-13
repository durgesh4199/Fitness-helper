import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/daily_wellness.dart';
import 'package:fitness_tracker/models/nutrition_targets.dart';
import 'package:fitness_tracker/providers/nutrition_provider.dart';
import 'package:fitness_tracker/providers/user_provider.dart';

final _targets = NutritionTargets.compute(
  weightKg: 70,
  heightCm: 175,
  age: 30,
  sex: Sex.male,
  activity: ActivityLevel.moderate,
  goalWeightKg: 70,
);

void main() {
  group('DailyWellnessCalculator.compute', () {
    test('a day with everything on target scores highly and labels Great', () {
      final totals = NutritionTotals(
        calories: _targets.calories.toDouble(),
        protein: _targets.protein.toDouble(),
        fiber: _targets.fiber.toDouble(),
      );
      final result = DailyWellnessCalculator.compute(
        totals: totals,
        targets: _targets,
        waterIntakeMl: _targets.waterMl,
        waterGoalMl: _targets.waterMl,
        steps: 8000,
        stepGoal: 8000,
        sleepMinutes: 480, // 8h, inside the ideal window
        todayWorkoutMinutes: 30,
        weekWorkoutCount: 4,
      );

      expect(result.score, greaterThanOrEqualTo(80));
      expect(result.label, 'Great');
      expect(result.components, hasLength(5));
    });

    test('an empty day scores low', () {
      final result = DailyWellnessCalculator.compute(
        totals: const NutritionTotals(),
        targets: _targets,
        waterIntakeMl: 0,
        waterGoalMl: _targets.waterMl,
        todayWorkoutMinutes: 0,
        weekWorkoutCount: 0,
      );

      expect(result.score, lessThan(50));
      expect(result.label, 'Needs attention');
    });

    test('sleep is omitted from the components when there is no reading', () {
      final result = DailyWellnessCalculator.compute(
        totals: const NutritionTotals(),
        targets: _targets,
        waterIntakeMl: 0,
        waterGoalMl: _targets.waterMl,
        sleepMinutes: null,
        todayWorkoutMinutes: 0,
        weekWorkoutCount: 0,
      );

      expect(result.components.any((c) => c.component == WellnessComponent.sleep), isFalse);
      expect(result.components, hasLength(4));
    });

    test('activity falls back to workout minutes when there is no step goal', () {
      final withWorkout = DailyWellnessCalculator.compute(
        totals: const NutritionTotals(),
        targets: _targets,
        waterIntakeMl: 0,
        waterGoalMl: _targets.waterMl,
        steps: null,
        stepGoal: null,
        todayWorkoutMinutes: 30,
        weekWorkoutCount: 0,
      );
      final activity = withWorkout.components.firstWhere((c) => c.component == WellnessComponent.activity);
      expect(activity.score, 100);
    });

    test('sleep outside the ideal window scores below 100 but above 0', () {
      final result = DailyWellnessCalculator.compute(
        totals: const NutritionTotals(),
        targets: _targets,
        waterIntakeMl: 0,
        waterGoalMl: _targets.waterMl,
        sleepMinutes: 300, // 5h — short of the 7h floor
        todayWorkoutMinutes: 0,
        weekWorkoutCount: 0,
      );
      final sleep = result.components.firstWhere((c) => c.component == WellnessComponent.sleep);
      expect(sleep.score, lessThan(100));
      expect(sleep.score, greaterThanOrEqualTo(0));
    });
  });

  group('DailyWellnessCalculator.focusSuggestions', () {
    test('suggests the biggest gaps first, capped at 4', () {
      final suggestions = DailyWellnessCalculator.focusSuggestions(
        totals: const NutritionTotals(), // nothing logged: protein/fiber both 100% short
        targets: _targets,
        waterIntakeMl: 0,
        waterGoalMl: _targets.waterMl,
        steps: 500,
        stepGoal: 8000,
        sleepMinutes: 300,
      );

      expect(suggestions.length, lessThanOrEqualTo(4));
      expect(suggestions, contains('Drink water'));
    });

    test('a sleep shortfall surfaces once nutrition/hydration/steps are mostly on track', () {
      final totals = NutritionTotals(
        protein: _targets.protein * 0.85,
        fiber: _targets.fiber * 0.85,
      );
      final suggestions = DailyWellnessCalculator.focusSuggestions(
        totals: totals,
        targets: _targets,
        waterIntakeMl: (_targets.waterMl * 0.9).round(),
        waterGoalMl: _targets.waterMl,
        steps: 7500,
        stepGoal: 8000,
        sleepMinutes: 120, // well short of the 7h floor — the clear worst gap here
      );

      expect(suggestions.first, 'Prioritize sleep tonight');
    });

    test('suggests nothing once targets are already met', () {
      final totals = NutritionTotals(protein: _targets.protein.toDouble(), fiber: _targets.fiber.toDouble());
      final suggestions = DailyWellnessCalculator.focusSuggestions(
        totals: totals,
        targets: _targets,
        waterIntakeMl: _targets.waterMl,
        waterGoalMl: _targets.waterMl,
        steps: 9000,
        stepGoal: 8000,
        sleepMinutes: 480,
      );

      expect(suggestions, isEmpty);
    });

    test('never suggests sleep or steps when there is no reading for them', () {
      final suggestions = DailyWellnessCalculator.focusSuggestions(
        totals: const NutritionTotals(),
        targets: _targets,
        waterIntakeMl: 0,
        waterGoalMl: _targets.waterMl,
        steps: null,
        stepGoal: null,
        sleepMinutes: null,
      );

      expect(suggestions, isNot(contains('Prioritize sleep tonight')));
      expect(suggestions, isNot(contains('Take a short walk')));
    });
  });
}
