import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/models/iron_bioavailability_analyzer.dart';

FoodLog _log({
  String name = 'Food',
  String category = 'Grains & Breads',
  double iron = 0,
  double vitaminC = 0,
  double caffeine = 0,
  bool? containsHemeIron,
  bool? phytateContext,
  bool? oxalateContext,
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
    iron: iron,
    calcium: 0,
    vitaminC: vitaminC,
    caffeine: caffeine,
    containsHemeIron: containsHemeIron,
    phytateContext: phytateContext,
    oxalateContext: oxalateContext,
    dateTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('IronBioavailabilityAnalyzer.analyze', () {
    test('returns null when the meal has no iron at all', () {
      final ctx = MealContextBuilder.build([_log(iron: 0)]);
      expect(IronBioavailabilityAnalyzer.analyze(ctx), isNull);
    });

    test('heme iron with no inhibitors: high availability, no inhibitors listed', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Chicken Curry', category: 'Non-Veg', iron: 1.8, containsHemeIron: true),
      ]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.inhibitors, isEmpty);
      expect(estimate.contextualFactors, contains(contains('heme iron')));
    });

    test('non-heme iron + vitamin C: high availability, vitamin C listed as an enhancer', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Dal', iron: 2.4, phytateContext: false),
        _log(name: 'Lemon', vitaminC: 30),
      ]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.high);
      expect(estimate.enhancers, contains('Vitamin C present'));
      expect(estimate.recommendations, isEmpty); // already has an enhancer and no inhibitor
    });

    test('non-heme iron + phytate, no vitamin C: lower availability with a recommendation', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Dal', iron: 2.4, phytateContext: true),
      ]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.low);
      expect(estimate.inhibitors, contains(contains('Phytate')));
      expect(estimate.recommendations, isNotEmpty);
      expect(estimate.recommendations.first, contains('vitamin-C-rich'));
    });

    test('tea/coffee context is recorded as an inhibitor and prompts a timing recommendation', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Dal', iron: 2.4),
        _log(name: 'Masala Chai', category: 'Beverages', caffeine: 40),
      ]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.inhibitors, contains(contains('Tea/coffee')));
      expect(estimate.recommendations.any((r) => r.contains('tea/coffee')), isTrue);
    });

    test('unknown phytate context is never treated as an inhibitor', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Mystery grain', iron: 1.5), // phytateContext left null
      ]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.inhibitors, isEmpty);
      // No enhancer, no inhibitor -> moderate, not penalized for the unknown.
      expect(estimate.level, BioavailabilityLevel.moderate);
    });

    test('confidence is high when the iron-contributing foods are context-assessed', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Chicken Curry', category: 'Non-Veg', iron: 1.8, containsHemeIron: true),
      ]);
      expect(IronBioavailabilityAnalyzer.analyze(ctx)!.confidence, EvidenceConfidence.high);
    });

    test('confidence is low when none of the iron-contributing foods have context data', () {
      final ctx = MealContextBuilder.build([_log(name: 'Unknown item', iron: 1.5)]);
      expect(IronBioavailabilityAnalyzer.analyze(ctx)!.confidence, EvidenceConfidence.low);
    });

    test('confidence is medium with a mix of assessed and unassessed iron foods', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Dal', iron: 2.4, phytateContext: true),
        _log(name: 'Unknown item', iron: 1.0),
      ]);
      expect(IronBioavailabilityAnalyzer.analyze(ctx)!.confidence, EvidenceConfidence.medium);
    });

    test('mixed meal (heme + non-heme, with an inhibitor) never drops below moderate', () {
      final ctx = MealContextBuilder.build([
        _log(name: 'Chicken Curry', category: 'Non-Veg', iron: 1.8, containsHemeIron: true),
        _log(name: 'Dal', iron: 2.4, phytateContext: true),
      ]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level.index, greaterThanOrEqualTo(BioavailabilityLevel.moderate.index));
    });

    test('unclassified iron source with no enhancer/inhibitor signal defaults to a moderate baseline with low confidence', () {
      final ctx = MealContextBuilder.build([_log(name: 'Mystery food', iron: 1.0)]);
      // No heme flag, no phytate/oxalate flag, no vitamin C, no tea/coffee.
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.level, BioavailabilityLevel.moderate);
      expect(estimate.confidence, EvidenceConfidence.low);
    });

    test('never expresses the result as a claimed absorbed amount', () {
      final ctx = MealContextBuilder.build([_log(iron: 2.4, phytateContext: true)]);
      final estimate = IronBioavailabilityAnalyzer.analyze(ctx)!;
      expect(estimate.explanation.toLowerCase(), isNot(contains('absorbed')));
      expect(estimate.explanation.toLowerCase(), isNot(contains('you absorbed')));
    });
  });
}
