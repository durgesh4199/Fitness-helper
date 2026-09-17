import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/models/fat_soluble_vitamin_analyzer.dart';
import 'package:fitness_tracker/models/food_log.dart';

FoodLog _log({String name = 'Food', String category = 'Non-Veg', double fat = 0}) {
  return FoodLog(
    name: name,
    category: category,
    meal: 'Lunch',
    servings: 1,
    calories: 100,
    protein: 5,
    carbs: 10,
    fiber: 2,
    fat: fat,
    sugar: 0,
    iron: 0,
    calcium: 0,
    vitaminC: 0,
    caffeine: 0,
    dateTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('FatSolubleVitaminAnalyzer.analyze', () {
    test('returns null when intake is zero', () {
      final ctx = MealContextBuilder.build([_log()]);
      expect(FatSolubleVitaminAnalyzer.analyze(ctx, nutrientLabel: 'Vitamin A', intake: 0), isNull);
    });

    test('a meal with dietary fat: high level, fat listed as an enhancer', () {
      final ctx = MealContextBuilder.build([_log(fat: 5)]);
      final estimate = FatSolubleVitaminAnalyzer.analyze(ctx, nutrientLabel: 'Vitamin D', intake: 1.0)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.enhancers, contains(contains('fat')));
      expect(estimate.recommendations, isEmpty);
    });

    test('a meal with no meaningful dietary fat: moderate (not low), with a recommendation', () {
      final ctx = MealContextBuilder.build([_log(fat: 0)]);
      final estimate = FatSolubleVitaminAnalyzer.analyze(ctx, nutrientLabel: 'Vitamin K', intake: 10)!;
      expect(estimate.level, BioavailabilityLevel.moderate);
      expect(estimate.recommendations, isNotEmpty);
      expect(estimate.recommendations.first, contains('Vitamin K'));
    });

    test('never reports a low or very-low level -- there is no established inhibitor tracked', () {
      final ctx = MealContextBuilder.build([_log(fat: 0)]);
      final estimate = FatSolubleVitaminAnalyzer.analyze(ctx, nutrientLabel: 'Vitamin E', intake: 2)!;
      expect(estimate.level, isNot(BioavailabilityLevel.low));
      expect(estimate.level, isNot(BioavailabilityLevel.veryLow));
    });

    test('never expresses the result as a claimed absorbed amount', () {
      final ctx = MealContextBuilder.build([_log(fat: 5)]);
      final estimate = FatSolubleVitaminAnalyzer.analyze(ctx, nutrientLabel: 'Vitamin A', intake: 75)!;
      expect(estimate.explanation.toLowerCase(), isNot(contains('you absorbed')));
      expect(estimate.intake, 75);
    });
  });
}
