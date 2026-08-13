import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/nutrition_targets.dart';
import 'package:fitness_tracker/providers/user_provider.dart';

void main() {
  group('NutritionTargets.compute', () {
    test('higher activity level raises the calorie target (BMR x activity factor)', () {
      final sedentary = NutritionTargets.compute(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        activity: ActivityLevel.sedentary,
        goalWeightKg: 70,
      );
      final active = NutritionTargets.compute(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        activity: ActivityLevel.active,
        goalWeightKg: 70,
      );
      expect(active.calories, greaterThan(sedentary.calories));
    });

    test('goal weight equal to current weight is labeled Maintain', () {
      final t = NutritionTargets.compute(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        activity: ActivityLevel.moderate,
        goalWeightKg: 70,
      );
      expect(t.goalLabel, 'Maintain');
    });

    test('a lower goal weight reduces calories below maintenance', () {
      final maintain = NutritionTargets.compute(
        weightKg: 80,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        activity: ActivityLevel.moderate,
        goalWeightKg: 80,
      );
      final lose = NutritionTargets.compute(
        weightKg: 80,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        activity: ActivityLevel.moderate,
        goalWeightKg: 70,
      );
      expect(lose.calories, lessThan(maintain.calories));
      expect(lose.goalLabel, 'Lose weight');
    });

    test('calories never drop below resting BMR even for an aggressive goal', () {
      final t = NutritionTargets.compute(
        weightKg: 50,
        heightCm: 150,
        age: 60,
        sex: Sex.female,
        activity: ActivityLevel.sedentary,
        goalWeightKg: 30,
      );
      final bmr = 10 * 50 + 6.25 * 150 - 5 * 60 - 161;
      expect(t.calories, greaterThanOrEqualTo(bmr.round()));
    });

    test('female RDA for iron is higher than male in the 19-50 age band', () {
      final female = NutritionTargets.compute(
        weightKg: 60,
        heightCm: 165,
        age: 30,
        sex: Sex.female,
        activity: ActivityLevel.moderate,
        goalWeightKg: 60,
      );
      final male = NutritionTargets.compute(
        weightKg: 60,
        heightCm: 165,
        age: 30,
        sex: Sex.male,
        activity: ActivityLevel.moderate,
        goalWeightKg: 60,
      );
      expect(female.iron, greaterThan(male.iron));
    });
  });
}
