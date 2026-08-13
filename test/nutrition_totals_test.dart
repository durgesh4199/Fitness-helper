import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/providers/nutrition_provider.dart';

FoodLog _log({double? magnesium, double? potassium, double? zinc}) {
  return FoodLog(
    name: 'Test food',
    category: 'Grains & Breads',
    meal: 'Lunch',
    servings: 1,
    calories: 100,
    protein: 5,
    carbs: 10,
    fiber: 2,
    fat: 3,
    sugar: 1,
    iron: 1,
    calcium: 10,
    vitaminC: 2,
    caffeine: 0,
    magnesium: magnesium,
    potassium: potassium,
    zinc: zinc,
    dateTime: DateTime(2026, 1, 1, 12),
  );
}

void main() {
  group('NutritionTotals known/partial tracking', () {
    test('an empty total is trivially "known" for every micronutrient', () {
      const totals = NutritionTotals();
      expect(totals.magnesiumKnown, isTrue);
      expect(totals.potassiumKnown, isTrue);
      expect(totals.zincKnown, isTrue);
    });

    test('stays known when every summed log has a value', () {
      final totals = const NutritionTotals() +
          _log(magnesium: 20, potassium: 100, zinc: 1) +
          _log(magnesium: 10, potassium: 50, zinc: 0.5);

      expect(totals.magnesium, 30);
      expect(totals.potassium, 150);
      expect(totals.zinc, 1.5);
      expect(totals.magnesiumKnown, isTrue);
      expect(totals.potassiumKnown, isTrue);
      expect(totals.zincKnown, isTrue);
    });

    test('becomes partial (known=false) once any summed log lacks a value', () {
      final totals = const NutritionTotals() +
          _log(magnesium: 20, potassium: 100, zinc: 1) +
          _log(); // no micronutrient data at all

      // Sum only reflects the log(s) that had data — a lower bound, not 0.
      expect(totals.magnesium, 20);
      expect(totals.potassium, 100);
      expect(totals.zinc, 1);
      expect(totals.magnesiumKnown, isFalse);
      expect(totals.potassiumKnown, isFalse);
      expect(totals.zincKnown, isFalse);
    });

    test('one nutrient can be partial while another stays complete', () {
      final totals = const NutritionTotals() +
          _log(magnesium: 20, potassium: null, zinc: 1) +
          _log(magnesium: 10, potassium: null, zinc: 0.5);

      expect(totals.magnesiumKnown, isTrue);
      expect(totals.zincKnown, isTrue);
      expect(totals.potassiumKnown, isFalse);
      expect(totals.potassium, 0);
    });
  });
}
