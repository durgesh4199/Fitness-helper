import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/food_item.dart';
import 'package:fitness_tracker/models/food_recommendation.dart';

const _catalog = [
  FoodItem(
    name: 'Curd / Dahi',
    category: 'Dairy',
    serving: '1 bowl (150g)',
    calories: 100,
    protein: 6,
    carbs: 8,
    fiber: 0,
    fat: 5,
    sugar: 6,
    calcium: 200,
  ),
  FoodItem(
    name: 'Upma',
    category: 'Grains & Breads',
    serving: '1 bowl (150g)',
    calories: 250,
    protein: 6,
    carbs: 40,
    fiber: 3,
    fat: 8,
    sugar: 1,
    iron: 1.5,
    calcium: 25,
  ),
  FoodItem(
    name: 'Ghee',
    category: 'Dairy',
    serving: '1 tbsp (14g)',
    calories: 112,
    protein: 0,
    carbs: 0,
    fiber: 0,
    fat: 12.5,
    sugar: 0,
  ), // oily -> should never be recommended
  FoodItem(
    name: 'Gulab Jamun',
    category: 'Sweets',
    serving: '2 pieces',
    calories: 300,
    protein: 4,
    carbs: 70,
    fiber: 1,
    fat: 10,
    sugar: 55,
  ), // sugar-unsafe for diabetics
];

void main() {
  group('FoodRecommendationEngine.recommendCombinations', () {
    test('pairs foods that together close more of the remaining gaps', () {
      final combos = FoodRecommendationEngine.recommendCombinations(
        remaining: const {
          RecommendedNutrient.protein: 20,
          RecommendedNutrient.fiber: 8,
          RecommendedNutrient.calcium: 300,
        },
        remainingCalories: 800,
        catalog: _catalog,
        diabetic: false,
      );

      expect(combos, isNotEmpty);
      final top = combos.first;
      // Combined protein/fiber/calcium should reflect both foods' contributions.
      expect(top.combinedAmounts[RecommendedNutrient.protein], greaterThan(0));
      expect(top.combinedCalories, top.first.calories + top.second.calories);
    });

    test('never includes an oily food (Ghee) in a combo', () {
      final combos = FoodRecommendationEngine.recommendCombinations(
        remaining: const {RecommendedNutrient.protein: 20, RecommendedNutrient.calcium: 300},
        remainingCalories: 800,
        catalog: _catalog,
        diabetic: false,
      );

      for (final c in combos) {
        expect(c.first.name, isNot('Ghee'));
        expect(c.second.name, isNot('Ghee'));
      }
    });

    test('excludes sugar-unsafe foods for a diabetic user', () {
      final combos = FoodRecommendationEngine.recommendCombinations(
        remaining: const {RecommendedNutrient.protein: 20, RecommendedNutrient.fiber: 8},
        remainingCalories: 800,
        catalog: _catalog,
        diabetic: true,
      );

      for (final c in combos) {
        expect(c.first.name, isNot('Gulab Jamun'));
        expect(c.second.name, isNot('Gulab Jamun'));
      }
    });

    test('respects the remaining-calorie budget', () {
      final combos = FoodRecommendationEngine.recommendCombinations(
        remaining: const {RecommendedNutrient.protein: 20, RecommendedNutrient.fiber: 8, RecommendedNutrient.calcium: 300},
        remainingCalories: 50, // too small for any safe pair (min pair here is Curd+Upma = 350kcal)
        catalog: _catalog,
        diabetic: false,
      );

      expect(combos, isEmpty);
    });

    test('returns nothing when there are fewer than 2 viable candidates', () {
      final combos = FoodRecommendationEngine.recommendCombinations(
        remaining: const {RecommendedNutrient.protein: 20},
        remainingCalories: 800,
        catalog: [_catalog[0]], // only one candidate
        diabetic: false,
      );

      expect(combos, isEmpty);
    });
  });
}
