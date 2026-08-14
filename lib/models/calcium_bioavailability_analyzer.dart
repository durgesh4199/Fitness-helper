import 'bioavailability.dart';

/// Estimates how favorable a meal's context looks for calcium
/// bioavailability — never how much calcium was actually absorbed, and
/// deliberately never a universal formula like "absorbed = calcium * 0.35"
/// (the spec explicitly forbids this — real calcium absorption varies
/// heavily by source and this app has no way to measure an individual's
/// actual absorption).
///
/// Core facts this analyzer relies on (well-established, not estimated):
/// - Dairy is a well-established, reasonably-bioavailable calcium source.
/// - High-oxalate foods (e.g. spinach) are a well-known inhibitor of
///   calcium absorption — most notably, spinach's own calcium is poorly
///   absorbed because of its own oxalate content.
/// - Phytates (legumes, whole grains) are a secondary known inhibitor.
class CalciumBioavailabilityAnalyzer {
  CalciumBioavailabilityAnalyzer._();

  static const String nutrient = 'Calcium';

  /// Returns null when the meal has no calcium at all — nothing to analyze.
  static BioavailabilityEstimate? analyze(MealContext meal) {
    if (meal.isEmpty || meal.totalCalcium <= 0) return null;

    final enhancers = <String>[];
    final inhibitors = <String>[];
    final contextual = <String>[];
    final recommendations = <String>[];

    if (meal.containsDairyFood) {
      enhancers.add('Dairy-source calcium present');
    }
    if (meal.containsOxalateRichFood) {
      inhibitors.add('High-oxalate foods (e.g. spinach)');
    }
    if (meal.containsPhytateRichFood) {
      inhibitors.add('Phytate-rich foods (legumes/whole grains)');
    }

    final level = _level(hasDairy: meal.containsDairyFood, inhibitorCount: inhibitors.length);
    final confidence = _confidence(meal);

    if (meal.containsOxalateRichFood && !meal.containsDairyFood) {
      recommendations.add('This meal\'s calcium is mainly from a high-oxalate source — a dairy or fortified food elsewhere in the day may be more reliably absorbed.');
    }

    if (meal.containsOxalateRichFood && meal.containsDairyFood) {
      contextual.add('Calcium in this meal comes from both a dairy source and a high-oxalate food');
    }

    return BioavailabilityEstimate(
      nutrient: nutrient,
      intake: meal.totalCalcium,
      level: level,
      confidence: confidence,
      enhancers: enhancers,
      inhibitors: inhibitors,
      contextualFactors: contextual,
      recommendations: recommendations,
      explanation: _explanation(level, meal),
    );
  }

  static BioavailabilityLevel _level({required bool hasDairy, required int inhibitorCount}) {
    if (inhibitorCount == 0 && hasDairy) return BioavailabilityLevel.high;
    if (inhibitorCount == 0 && !hasDairy) return BioavailabilityLevel.moderate;
    if (inhibitorCount >= 1 && hasDairy) return BioavailabilityLevel.moderate;
    return BioavailabilityLevel.low; // inhibitor(s) present, no dairy source
  }

  /// High when we know the source context (dairy vs. not) and oxalate/
  /// phytate status for most of the meal's calcium-contributing foods.
  static EvidenceConfidence _confidence(MealContext meal) {
    final calciumFoods = meal.foods.where((l) => l.calcium > 0).toList();
    if (calciumFoods.isEmpty) return EvidenceConfidence.low;

    final assessed = calciumFoods.where(
      (l) => l.category.toLowerCase() == 'dairy' || l.oxalateContext != null || l.phytateContext != null,
    );
    final ratio = assessed.length / calciumFoods.length;

    if (ratio >= 0.8) return EvidenceConfidence.high;
    if (ratio > 0) return EvidenceConfidence.medium;
    return EvidenceConfidence.low;
  }

  static String _explanation(BioavailabilityLevel level, MealContext meal) {
    switch (level) {
      case BioavailabilityLevel.high:
        return 'This meal\'s calcium comes from a dairy source with no major inhibitors present — a favorable context.';
      case BioavailabilityLevel.moderate:
        return meal.containsDairyFood
            ? 'This meal has a dairy calcium source alongside a potential inhibitor — a moderately favorable context overall.'
            : 'This meal contains calcium without a known inhibitor, though the source context isn\'t a well-established high-bioavailability one like dairy.';
      case BioavailabilityLevel.low:
        return 'This meal\'s calcium is mainly from a high-oxalate or phytate-rich source without a dairy source alongside it — a less favorable context for absorption.';
      case BioavailabilityLevel.veryLow:
        return 'Multiple potential inhibitors are present with no offsetting dairy source — likely a less favorable context for absorption.';
      case BioavailabilityLevel.veryHigh:
        return 'This meal has strong supporting factors for calcium availability.';
      case BioavailabilityLevel.unknown:
        return 'There isn\'t enough data on these foods yet to estimate the meal context for calcium.';
    }
  }
}
