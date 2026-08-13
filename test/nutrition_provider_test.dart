import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/providers/nutrition_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NutritionProvider.spikeImpact (pure heuristic, no DB)', () {
    test('more sugar increases the impact for the same carbs/fiber', () {
      final low = NutritionProvider.spikeImpact(sugar: 5, carbs: 20, fiber: 2);
      final high = NutritionProvider.spikeImpact(sugar: 30, carbs: 20, fiber: 2);
      expect(high, greaterThan(low));
    });

    test('fiber dampens the impact of the same carbs/sugar', () {
      final noFiber = NutritionProvider.spikeImpact(sugar: 20, carbs: 40, fiber: 0);
      final withFiber = NutritionProvider.spikeImpact(sugar: 20, carbs: 40, fiber: 15);
      expect(withFiber, lessThan(noFiber));
    });

    test('diabetic sensitivity increases the impact for identical intake', () {
      final nonDiabetic = NutritionProvider.spikeImpact(sugar: 20, carbs: 40, fiber: 5, diabetic: false);
      final diabetic = NutritionProvider.spikeImpact(sugar: 20, carbs: 40, fiber: 5, diabetic: true);
      expect(diabetic, greaterThan(nonDiabetic));
    });
  });

  group('NutritionProvider.mealImpactEstimateForDate', () {
    late NutritionProvider provider;

    setUp(() async {
      provider = NutritionProvider();
      await provider.load();
      // Start each test from a clean slate regardless of leftover state
      // from a previous local test run against the same sqlite file.
      for (final log in List.of(provider.logs)) {
        if (log.id != null) await provider.deleteLog(log.id!);
      }
    });

    test('a day with no carb/sugar logs has no estimate', () {
      final estimate = provider.mealImpactEstimateForDate(DateTime.now());
      expect(estimate.hasData, isFalse);
    });

    test('confidence stays Low with a single logged item', () async {
      final now = DateTime.now();
      await provider.addLog(FoodLog(
        name: 'Test sweet',
        category: 'Sweets',
        meal: 'Snacks',
        servings: 1,
        calories: 400,
        protein: 2,
        carbs: 80,
        fiber: 1,
        fat: 5,
        sugar: 60,
        iron: 0,
        calcium: 0,
        vitaminC: 0,
        caffeine: 0,
        dateTime: now,
      ));

      final estimate = provider.mealImpactEstimateForDate(now);
      expect(estimate.hasData, isTrue);
      expect(estimate.confidence, 'Low');
      // Never High — this is a heuristic, not a lab reading.
      expect(estimate.confidence, isNot('High'));
    });

    test('a high-sugar, low-fiber day produces an elevated impact level', () async {
      final now = DateTime.now();
      await provider.addLog(FoodLog(
        name: 'Sugary snack',
        category: 'Sweets',
        meal: 'Snacks',
        servings: 1,
        calories: 500,
        protein: 2,
        carbs: 100,
        fiber: 0,
        fat: 5,
        sugar: 80,
        iron: 0,
        calcium: 0,
        vitaminC: 0,
        caffeine: 0,
        dateTime: now,
      ));

      final estimate = provider.mealImpactEstimateForDate(now);
      expect(
        estimate.level,
        anyOf(MealImpactLevel.high, MealImpactLevel.veryHigh, MealImpactLevel.moderate),
      );
      expect(estimate.sugar, 'High');
    });
  });
}
