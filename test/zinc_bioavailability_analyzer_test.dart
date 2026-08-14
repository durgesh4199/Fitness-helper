import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/models/zinc_bioavailability_analyzer.dart';

FoodLog _log({
  String name = 'Food',
  String category = 'Grains & Breads',
  double zinc = 0,
  bool? isAnimalProtein,
  bool? isPlantProtein,
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
    calcium: 0,
    vitaminC: 0,
    caffeine: 0,
    zinc: zinc,
    isAnimalProtein: isAnimalProtein,
    isPlantProtein: isPlantProtein,
    phytateContext: phytateContext,
    dateTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ZincBioavailabilityAnalyzer.analyze', () {
    test('returns null when the meal has no zinc', () {
      final ctx = MealContextBuilder.build([_log(zinc: 0)]);
      expect(ZincBioavailabilityAnalyzer.analyze(ctx), isNull);
    });

    test('low phytate context (animal source, no phytate): high availability', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Chicken Curry', category: 'Non-Veg', zinc: 1.8, isAnimalProtein: true, phytateContext: false),
      ]);
      final estimate = ZincBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.enhancers, contains('Animal-source food present'));
      expect(estimate.inhibitors, isEmpty);
    });

    test('high phytate context (plant-only, phytate-rich): lower availability with a recommendation', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Dal', zinc: 1.5, isPlantProtein: true, phytateContext: true),
      ]);
      final estimate = ZincBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.low);
      expect(estimate.inhibitors, contains(contains('Phytate')));
      expect(estimate.recommendations, isNotEmpty);
    });

    test('unknown phytate context is never treated as an inhibitor', () {
      final ctx = MealContextBuilder.build([_log(name: 'Mystery food', zinc: 1.0)]);
      final estimate = ZincBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.inhibitors, isEmpty);
      expect(estimate.level, BioavailabilityLevel.moderate);
    });

    test('confidence is low when no zinc-contributing food has any context data', () {
      final ctx = MealContextBuilder.build([_log(zinc: 1.0)]);
      expect(ZincBioavailabilityAnalyzer.analyze(ctx)!.confidence, EvidenceConfidence.low);
    });

    test('confidence is high when zinc-contributing foods are context-assessed', () {
      final ctx = MealContextBuilder.build([
        _log(zinc: 1.0, isAnimalProtein: true, phytateContext: false),
      ]);
      expect(ZincBioavailabilityAnalyzer.analyze(ctx)!.confidence, EvidenceConfidence.high);
    });

    test('never expresses the result as a claimed absorbed amount', () {
      final ctx = MealContextBuilder.build([_log(zinc: 1.5, phytateContext: true)]);
      final estimate = ZincBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.explanation.toLowerCase(), isNot(contains('you absorbed')));
    });
  });
}
