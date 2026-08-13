import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/models/meal_quality.dart';

FoodLog _log({
  required String name,
  required String category,
  double protein = 0,
  double fiber = 0,
  double sugar = 0,
  double calories = 0,
}) {
  return FoodLog(
    name: name,
    category: category,
    meal: 'Lunch',
    servings: 1,
    calories: calories,
    protein: protein,
    carbs: 0,
    fiber: fiber,
    fat: 0,
    sugar: sugar,
    iron: 0,
    calcium: 0,
    vitaminC: 0,
    caffeine: 0,
    dateTime: DateTime(2026, 1, 1, 13),
  );
}

void main() {
  group('MealQualityScorer.score', () {
    test('empty meal scores 0 with no checks', () {
      final result = MealQualityScorer.score(const []);
      expect(result.score, 0);
      expect(result.checks, isEmpty);
    });

    test('a well-rounded meal meets all 5 factors', () {
      final logs = [
        _log(name: 'Rajma', category: 'Dals & Legumes', protein: 12, fiber: 8, sugar: 3, calories: 210),
        _log(name: 'Mixed Veg Curry', category: 'Vegetables', protein: 4, fiber: 5, sugar: 6, calories: 170),
      ];
      final result = MealQualityScorer.score(logs);
      expect(result.score, 100);
      expect(result.checks.values.every((v) => v), isTrue);
    });

    test('a low-protein, low-fiber, high-sugar meal flags those factors', () {
      final logs = [_log(name: 'Gulab Jamun', category: 'Sweets', protein: 2, fiber: 0, sugar: 30, calories: 300)];
      final result = MealQualityScorer.score(logs);
      expect(result.checks[MealQualityFactor.protein], isFalse);
      expect(result.checks[MealQualityFactor.fiber], isFalse);
      expect(result.checks[MealQualityFactor.sugar], isFalse);
      expect(result.checks[MealQualityFactor.vegetablesOrFruit], isFalse);
    });

    test('an oversized meal flags the portion-size (calories) factor', () {
      final logs = [_log(name: 'Feast', category: 'Grains & Breads', protein: 20, fiber: 10, sugar: 5, calories: 1200)];
      final result = MealQualityScorer.score(logs);
      expect(result.checks[MealQualityFactor.calories], isFalse);
    });

    test('a fruit item satisfies the vegetables/fruit factor', () {
      final logs = [_log(name: 'Banana', category: 'Fruits', protein: 1, fiber: 3, sugar: 12, calories: 100)];
      final result = MealQualityScorer.score(logs);
      expect(result.checks[MealQualityFactor.vegetablesOrFruit], isTrue);
    });
  });
}
