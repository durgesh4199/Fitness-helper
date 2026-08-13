import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/daily_habits.dart';
import 'package:fitness_tracker/models/food_log.dart';

FoodLog _log(String category) {
  return FoodLog(
    name: 'Test',
    category: category,
    meal: 'Lunch',
    servings: 1,
    calories: 100,
    protein: 2,
    carbs: 10,
    fiber: 2,
    fat: 1,
    sugar: 3,
    iron: 0,
    calcium: 0,
    vitaminC: 0,
    caffeine: 0,
    dateTime: DateTime(2026, 1, 1, 12),
  );
}

void main() {
  group('DailyHabits.compute', () {
    test('all habits unmet on a completely empty day', () {
      final habits = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 0,
        todayLogs: const [],
      );

      expect(habits.waterGoalMet, isFalse);
      expect(habits.workoutDone, isFalse);
      expect(habits.walked, isFalse);
      expect(habits.ateVegOrFruit, isFalse);
      expect(habits.sleepTargetMet, isNull); // no reading, not "unmet"
      expect(habits.totalCount, 4); // sleep excluded when unknown
    });

    test('water/workout/veg-fruit met when the underlying data says so', () {
      final habits = DailyHabits.compute(
        waterIntakeMl: 2600,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 30,
        todayLogs: [_log('Vegetables')],
      );

      expect(habits.waterGoalMet, isTrue);
      expect(habits.workoutDone, isTrue);
      expect(habits.ateVegOrFruit, isTrue);
    });

    test('walked uses the step goal when available, workout minutes otherwise', () {
      final metGoal = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 0,
        todayLogs: const [],
        steps: 9000,
        stepGoal: 8000,
      );
      final belowGoal = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 0,
        todayLogs: const [],
        steps: 2000,
        stepGoal: 8000,
      );
      final noStepData = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 15,
        todayLogs: const [],
      );

      expect(metGoal.walked, isTrue);
      expect(belowGoal.walked, isFalse);
      expect(noStepData.walked, isTrue); // falls back to "did any workout happen"
    });

    test('sleep habit reflects the reading when present', () {
      final metSleep = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 0,
        todayLogs: const [],
        sleepMinutes: 450,
      );
      final shortSleep = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 0,
        todayLogs: const [],
        sleepMinutes: 300,
      );

      expect(metSleep.sleepTargetMet, isTrue);
      expect(metSleep.totalCount, 5);
      expect(shortSleep.sleepTargetMet, isFalse);
    });

    test('a fruit-category log also satisfies the veg/fruit habit', () {
      final habits = DailyHabits.compute(
        waterIntakeMl: 0,
        waterGoalMl: 2500,
        todayWorkoutMinutes: 0,
        todayLogs: [_log('Fruits')],
      );

      expect(habits.ateVegOrFruit, isTrue);
    });
  });
}
