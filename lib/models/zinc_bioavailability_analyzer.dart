import 'bioavailability.dart';

/// Estimates how favorable a meal's context looks for zinc bioavailability
/// — never how much zinc was actually absorbed.
///
/// Core facts this analyzer relies on (well-established, not estimated):
/// - Zinc from animal-source foods (meat, dairy, eggs) is generally more
///   bioavailable than zinc from plant sources.
/// - Phytates (legumes, whole grains, nuts, seeds — the same context flag
///   used by the Iron analyzer) are the primary known inhibitor of zinc
///   absorption.
class ZincBioavailabilityAnalyzer {
  ZincBioavailabilityAnalyzer._();

  static const String nutrient = 'Zinc';

  /// Returns null when the meal has no zinc at all — nothing to analyze.
  static BioavailabilityEstimate? analyze(MealContext meal) {
    if (meal.isEmpty || meal.totalZinc <= 0) return null;

    final enhancers = <String>[];
    final inhibitors = <String>[];
    final contextual = <String>[];
    final recommendations = <String>[];

    final phytateMitigated = meal.phytateFullyMitigatedBySprouting;

    if (meal.containsAnimalProteinFood) {
      enhancers.add('Animal-source food present');
    }
    if (meal.containsPhytateRichFood && !phytateMitigated) {
      inhibitors.add('Phytate-rich foods (legumes/whole grains)');
    } else if (phytateMitigated) {
      contextual.add('This meal\'s phytate-rich food is sprouted, which is known to reduce phytic acid content — more favorable than an unsprouted equivalent');
    }
    if (meal.containsPlantProteinFood && !meal.containsAnimalProteinFood) {
      contextual.add('This meal\'s zinc is primarily from plant sources');
    }

    final level = _level(hasEnhancer: enhancers.isNotEmpty, inhibitorCount: inhibitors.length);
    final confidence = _confidence(meal);

    if (meal.containsPhytateRichFood && !meal.containsAnimalProteinFood && !phytateMitigated) {
      recommendations.add(
        'Consider varied protein sources, or preparation such as soaking/sprouting, alongside phytate-rich foods.',
      );
    }

    return BioavailabilityEstimate(
      nutrient: nutrient,
      intake: meal.totalZinc,
      level: level,
      confidence: confidence,
      enhancers: enhancers,
      inhibitors: inhibitors,
      contextualFactors: contextual,
      recommendations: recommendations,
      explanation: _explanation(level),
    );
  }

  static BioavailabilityLevel _level({required bool hasEnhancer, required int inhibitorCount}) {
    if (hasEnhancer && inhibitorCount == 0) return BioavailabilityLevel.high;
    if (hasEnhancer && inhibitorCount >= 1) return BioavailabilityLevel.moderate;
    if (!hasEnhancer && inhibitorCount == 0) return BioavailabilityLevel.moderate;
    return BioavailabilityLevel.low;
  }

  /// High when we have animal/plant-source and phytate-context data for most
  /// of the meal's zinc-contributing foods; low when we have it for none.
  static EvidenceConfidence _confidence(MealContext meal) {
    final zincFoods = meal.foods.where((l) => (l.zinc ?? 0) > 0).toList();
    if (zincFoods.isEmpty) return EvidenceConfidence.low;

    final assessed = zincFoods.where(
      (l) => l.phytateContext != null || l.isAnimalProtein != null || l.isPlantProtein != null,
    );
    final ratio = assessed.length / zincFoods.length;

    if (ratio >= 0.8) return EvidenceConfidence.high;
    if (ratio > 0) return EvidenceConfidence.medium;
    return EvidenceConfidence.low;
  }

  static String _explanation(BioavailabilityLevel level) {
    switch (level) {
      case BioavailabilityLevel.high:
        return 'This meal includes an animal-source food and no major inhibitors — a context generally associated with better zinc availability.';
      case BioavailabilityLevel.moderate:
        return 'This meal contains zinc alongside a mix of helpful and inhibiting factors, or without enough data to say more — a moderate context overall.';
      case BioavailabilityLevel.low:
        return 'This meal\'s zinc is mainly from plant sources alongside phytate-rich foods, without an animal-source food — a less favorable context for absorption.';
      case BioavailabilityLevel.veryLow:
        return 'Multiple potential inhibitors are present with no offsetting factors — likely a less favorable context for absorption.';
      case BioavailabilityLevel.veryHigh:
        return 'This meal has strong supporting factors for zinc availability.';
      case BioavailabilityLevel.unknown:
        return 'There isn\'t enough data on these foods yet to estimate the meal context for zinc.';
    }
  }
}
