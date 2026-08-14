import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/models/protein_quality_analyzer.dart';

FoodLog _log({
  String name = 'Food',
  String category = 'Grains & Breads',
  double protein = 0,
  bool? isAnimalProtein,
  bool? isPlantProtein,
}) {
  return FoodLog(
    name: name,
    category: category,
    meal: 'Lunch',
    servings: 1,
    calories: 100,
    protein: protein,
    carbs: 10,
    fiber: 2,
    fat: 2,
    sugar: 0,
    iron: 0,
    calcium: 0,
    vitaminC: 0,
    caffeine: 0,
    isAnimalProtein: isAnimalProtein,
    isPlantProtein: isPlantProtein,
    dateTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ProteinQualityAnalyzer.analyze', () {
    test('returns null when the meal has no protein', () {
      final ctx = MealContextBuilder.build([_log(protein: 0)]);
      expect(ProteinQualityAnalyzer.analyze(ctx), isNull);
    });

    test('animal protein: high, a complete protein source on its own', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Chicken Curry', category: 'Non-Veg', protein: 25, isAnimalProtein: true),
      ]);
      final estimate = ProteinQualityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.enhancers, contains(contains('Animal protein')));
    });

    test('plant protein alone (no complementary source): moderate, with a pairing recommendation', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Dal', category: 'Dals & Legumes', protein: 9, isPlantProtein: true),
      ]);
      final estimate = ProteinQualityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.moderate);
      expect(estimate.recommendations, isNotEmpty);
    });

    test('rice + dal complementary pattern: high, flagged as a complementary combination', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Plain Rice', category: 'Grains & Breads', protein: 4, isPlantProtein: true),
        _log(name: 'Toor Dal', category: 'Dals & Legumes', protein: 9, isPlantProtein: true),
      ]);
      final estimate = ProteinQualityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.enhancers, contains(contains('Grain + legume')));
    });

    test('mixed protein meal (animal + plant): high', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Curd', category: 'Dairy', protein: 6, isAnimalProtein: true),
        _log(name: 'Dal', category: 'Dals & Legumes', protein: 9, isPlantProtein: true),
      ]);
      final estimate = ProteinQualityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
    });

    test('unknown protein-source metadata: level is unknown, not a fabricated guess', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Samosa', category: 'Snacks', protein: 4), // no isAnimalProtein/isPlantProtein set
      ]);
      final estimate = ProteinQualityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.unknown);
      expect(estimate.confidence, EvidenceConfidence.low);
    });

    test('never produces a DIAAS/PDCAAS-style numeric score', () {
      final ctx = MealContextBuilder.build([_log(protein: 10, isAnimalProtein: true)]);
      final estimate = ProteinQualityAnalyzer.analyze(ctx)!;
      // intake is the logged protein grams, not a fabricated quality score.
      expect(estimate.intake, 10);
      expect(estimate.explanation.toLowerCase(), isNot(contains('diaas')));
      expect(estimate.explanation.toLowerCase(), isNot(contains('pdcaas')));
    });
  });
}
