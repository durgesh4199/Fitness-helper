import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/models/calcium_bioavailability_analyzer.dart';
import 'package:fitness_tracker/models/food_log.dart';

FoodLog _log({
  String name = 'Food',
  String category = 'Dairy',
  double calcium = 0,
  bool? oxalateContext,
  bool? phytateContext,
}) {
  return FoodLog(
    name: name,
    category: category,
    meal: 'Lunch',
    servings: 1,
    calories: 100,
    protein: 5,
    carbs: 10,
    fiber: 2,
    fat: 2,
    sugar: 0,
    iron: 0,
    calcium: calcium,
    vitaminC: 0,
    caffeine: 0,
    oxalateContext: oxalateContext,
    phytateContext: phytateContext,
    dateTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('CalciumBioavailabilityAnalyzer.analyze', () {
    test('returns null when the meal has no calcium', () {
      final ctx = MealContextBuilder.build([_log(calcium: 0)]);
      expect(CalciumBioavailabilityAnalyzer.analyze(ctx), isNull);
    });

    test('dairy source, no inhibitors: high availability', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Milk', category: 'Dairy', calcium: 300),
      ]);
      final estimate = CalciumBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.enhancers, contains('Dairy-source calcium present'));
    });

    test('known oxalate context (spinach dish, no dairy): low availability with a recommendation', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Palak Sabzi', category: 'Vegetables', calcium: 100, oxalateContext: true),
      ]);
      final estimate = CalciumBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.low);
      expect(estimate.inhibitors, contains(contains('oxalate')));
      expect(estimate.recommendations, isNotEmpty);
    });

    test('known oxalate context alongside a dairy source (e.g. palak paneer): moderate, not low', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Palak Paneer', category: 'Vegetables', calcium: 210, oxalateContext: true),
        _log(name: 'Paneer', category: 'Dairy', calcium: 0),
      ]);
      // Simulate the dairy signal coming from category presence even without
      // extra calcium on that particular row.
      final ctx2 = MealContextBuilder.build([
        _log(name: 'Palak Paneer (dairy+oxalate)', category: 'Dairy', calcium: 210, oxalateContext: true),
      ]);
      for (final c in [ctx, ctx2]) {
        final estimate = CalciumBioavailabilityAnalyzer.analyze(c)!;
        expect(estimate.level, BioavailabilityLevel.moderate);
      }
    });

    test('unknown oxalate context is never treated as an inhibitor', () {
      final ctx = MealContextBuilder.build([_log(name: 'Mystery food', category: 'Snacks', calcium: 50)]);
      final estimate = CalciumBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.inhibitors, isEmpty);
      expect(estimate.level, BioavailabilityLevel.moderate);
    });

    test('confidence is high for an assessed dairy source, low for an unassessed non-dairy one', () {
      final dairy = MealContextBuilder.build([_log(name: 'Milk', category: 'Dairy', calcium: 300)]);
      final unknown = MealContextBuilder.build([_log(name: 'Mystery food', category: 'Snacks', calcium: 50)]);
      expect(CalciumBioavailabilityAnalyzer.analyze(dairy)!.confidence, EvidenceConfidence.high);
      expect(CalciumBioavailabilityAnalyzer.analyze(unknown)!.confidence, EvidenceConfidence.low);
    });

    test('never uses a universal absorption formula or claims an absorbed amount', () {
      final ctx = MealContextBuilder.build([_log(name: 'Milk', category: 'Dairy', calcium: 300)]);
      final estimate = CalciumBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.intake, 300); // the logged amount, not a fabricated absorbed figure
      expect(estimate.explanation.toLowerCase(), isNot(contains('absorbed')));
    });
  });
}
