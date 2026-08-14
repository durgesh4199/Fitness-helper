import 'bioavailability.dart';

/// Estimates a *qualitative* protein-quality context for a meal — never a
/// DIAAS/PDCAAS score or an "absorbed protein" figure, both of which this
/// app has no reliable per-food data to compute honestly.
///
/// Core facts this analyzer relies on (well-established, not estimated):
/// - Animal-source proteins (meat, dairy, eggs) are complete proteins on
///   their own.
/// - A grain + legume combination (e.g. rice + dal, roti + rajma) is a
///   classic complementary-protein pairing that covers each other's
///   limiting amino acids — a well-known nutrition-education staple, not a
///   fabricated score.
class ProteinQualityAnalyzer {
  ProteinQualityAnalyzer._();

  static const String nutrient = 'Protein Quality';

  static const _grainCategory = 'grains & breads';
  static const _legumeCategory = 'dals & legumes';

  /// Returns null when the meal has no protein at all — nothing to analyze.
  static BioavailabilityEstimate? analyze(MealContext meal) {
    if (meal.isEmpty || meal.totalProtein <= 0) return null;

    final enhancers = <String>[];
    final contextual = <String>[];
    final recommendations = <String>[];

    final hasComplementaryCombo = _hasGrainAndLegume(meal);
    if (meal.containsAnimalProteinFood) {
      enhancers.add('Animal protein present — a complete protein source on its own');
    }
    if (hasComplementaryCombo) {
      enhancers.add('Grain + legume combination present (e.g. rice/roti + dal) — complementary plant proteins');
    }

    BioavailabilityLevel level;
    if (meal.containsAnimalProteinFood || hasComplementaryCombo) {
      level = BioavailabilityLevel.high;
    } else if (meal.containsPlantProteinFood) {
      level = BioavailabilityLevel.moderate;
      contextual.add('Protein in this meal is from a single plant source');
      recommendations.add('Pair this plant protein with a grain or legume (e.g. dal + rice) for a more complete amino acid profile.');
    } else {
      level = BioavailabilityLevel.unknown;
    }

    return BioavailabilityEstimate(
      nutrient: nutrient,
      intake: meal.totalProtein,
      level: level,
      confidence: _confidence(meal),
      enhancers: enhancers,
      contextualFactors: contextual,
      recommendations: recommendations,
      explanation: _explanation(level),
    );
  }

  static bool _hasGrainAndLegume(MealContext meal) {
    final categories = meal.foods.map((f) => f.category.toLowerCase()).toSet();
    return categories.contains(_grainCategory) && categories.contains(_legumeCategory);
  }

  /// High when we know the protein source (plant/animal) for most of the
  /// meal's protein-contributing foods; low when we know it for none.
  static EvidenceConfidence _confidence(MealContext meal) {
    final proteinFoods = meal.foods.where((l) => l.protein > 0).toList();
    if (proteinFoods.isEmpty) return EvidenceConfidence.low;

    final assessed = proteinFoods.where((l) => l.isAnimalProtein != null || l.isPlantProtein != null);
    final ratio = assessed.length / proteinFoods.length;

    if (ratio >= 0.8) return EvidenceConfidence.high;
    if (ratio > 0) return EvidenceConfidence.medium;
    return EvidenceConfidence.low;
  }

  static String _explanation(BioavailabilityLevel level) {
    switch (level) {
      case BioavailabilityLevel.high:
        return 'This meal contains a complete protein source — either animal protein or a complementary grain + legume combination.';
      case BioavailabilityLevel.moderate:
        return 'This meal\'s protein comes from a single plant source — pairing it with a complementary source can round out the amino acid profile.';
      case BioavailabilityLevel.low:
      case BioavailabilityLevel.veryLow:
        return 'This meal has limited protein-quality context available.';
      case BioavailabilityLevel.veryHigh:
        return 'This meal has strong supporting factors for protein quality.';
      case BioavailabilityLevel.unknown:
        return 'There isn\'t enough data on these foods yet to say anything about protein quality for this meal.';
    }
  }
}
