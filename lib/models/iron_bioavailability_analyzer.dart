import 'bioavailability.dart';

/// Estimates how favorable a meal's context looks for iron bioavailability
/// — never how much iron was actually absorbed (this app has no way to
/// measure that). See docs/FIREBASE_SETUP.md sibling doc-comments across
/// this feature for the same caveat repeated at each surface.
///
/// Core facts this analyzer relies on (all well-established, not estimated):
/// - Heme iron comes only from animal muscle tissue (meat/poultry/fish) and
///   is absorbed relatively consistently regardless of the rest of the meal.
/// - Non-heme iron (everything else, including eggs and plant sources) is
///   much more sensitive to meal context: vitamin C enhances it; phytates
///   (legumes, whole grains), tea/coffee (polyphenols), and high-oxalate
///   foods (e.g. spinach) inhibit it.
class IronBioavailabilityAnalyzer {
  IronBioavailabilityAnalyzer._();

  static const String nutrient = 'Iron';

  /// Returns null when the meal has no iron at all — there's nothing to
  /// analyze, not a "very low" result.
  static BioavailabilityEstimate? analyze(MealContext meal) {
    if (meal.isEmpty || meal.totalIron <= 0) return null;

    final enhancers = <String>[];
    final inhibitors = <String>[];
    final contextual = <String>[];
    final recommendations = <String>[];

    if (meal.containsVitaminCRichFood) enhancers.add('Vitamin C present');
    if (meal.containsPhytateRichFood) inhibitors.add('Phytate-rich foods (legumes/whole grains)');
    if (meal.containsOxalateRichFood) inhibitors.add('High-oxalate foods (e.g. spinach)');
    if (meal.containsTeaOrCoffee) inhibitors.add('Tea/coffee near this meal');
    if (meal.containsHemeIronFood) {
      contextual.add('Contains heme iron (meat/poultry/fish) — typically absorbed consistently regardless of other meal factors');
    }

    final level = _level(meal, hasEnhancer: enhancers.isNotEmpty, inhibitorCount: inhibitors.length);
    final confidence = _confidence(meal);

    if (!meal.containsVitaminCRichFood && meal.containsNonHemeIronFood && inhibitors.isNotEmpty) {
      recommendations.add('Add a vitamin-C-rich food (citrus, amla, guava, tomato) to this iron-rich meal.');
    }
    if (meal.containsTeaOrCoffee && meal.containsNonHemeIronFood) {
      recommendations.add('Consider having tea/coffee an hour or so away from iron-rich meals.');
    }

    return BioavailabilityEstimate(
      nutrient: nutrient,
      intake: meal.totalIron,
      level: level,
      confidence: confidence,
      enhancers: enhancers,
      inhibitors: inhibitors,
      contextualFactors: contextual,
      recommendations: recommendations,
      explanation: _explanation(level, meal),
    );
  }

  static BioavailabilityLevel _level(MealContext meal, {required bool hasEnhancer, required int inhibitorCount}) {
    // Heme-only meal: well-absorbed regardless of plant-food inhibitors.
    if (meal.containsHemeIronFood && !meal.containsNonHemeIronFood) {
      return BioavailabilityLevel.high;
    }

    // Non-heme iron present (possibly alongside heme iron too). Note: every
    // food with iron > 0 is classified as heme or non-heme by definition —
    // heme iron only exists in meat/poultry/fish muscle tissue, so the
    // absence of that flag is itself a known fact, not missing data (see
    // MealContextBuilder). How *much* we actually know about this specific
    // meal's enhancer/inhibitor context is instead reflected in
    // [_confidence], not in the level itself.
    BioavailabilityLevel level;
    if (hasEnhancer && inhibitorCount == 0) {
      level = BioavailabilityLevel.high;
    } else if (hasEnhancer && inhibitorCount >= 1) {
      level = BioavailabilityLevel.moderate;
    } else if (!hasEnhancer && inhibitorCount == 0) {
      level = BioavailabilityLevel.moderate;
    } else if (!hasEnhancer && inhibitorCount == 1) {
      level = BioavailabilityLevel.low;
    } else {
      level = BioavailabilityLevel.veryLow;
    }

    // A mixed meal (heme + non-heme) is never worse than moderate — the
    // heme portion is absorbed regardless of what's dragging the non-heme
    // estimate down.
    if (meal.containsHemeIronFood && level.index < BioavailabilityLevel.moderate.index) {
      level = BioavailabilityLevel.moderate;
    }
    return level;
  }

  /// High when we have context data (phytate/oxalate assessment, or a heme
  /// classification) for most of the meal's iron-contributing foods; low
  /// when we have it for none. This reflects confidence in *this app's
  /// context analysis*, not medical certainty.
  static EvidenceConfidence _confidence(MealContext meal) {
    final ironFoods = meal.foods.where((l) => l.iron > 0).toList();
    if (ironFoods.isEmpty) return EvidenceConfidence.low;

    final assessed = ironFoods.where(
      (l) => l.containsHemeIron == true || l.phytateContext != null || l.oxalateContext != null,
    );
    final ratio = assessed.length / ironFoods.length;

    if (ratio >= 0.8) return EvidenceConfidence.high;
    if (ratio > 0) return EvidenceConfidence.medium;
    return EvidenceConfidence.low;
  }

  static String _explanation(BioavailabilityLevel level, MealContext meal) {
    switch (level) {
      case BioavailabilityLevel.high:
        return meal.containsHemeIronFood
            ? 'This meal contains heme iron (from meat/poultry/fish), which is typically absorbed consistently.'
            : 'This meal pairs iron-rich foods with a vitamin-C source and has no major inhibitors present, a context generally associated with better non-heme iron availability.';
      case BioavailabilityLevel.moderate:
        return 'This meal contains iron alongside a mix of helpful and inhibiting factors — a moderately favorable context overall.';
      case BioavailabilityLevel.low:
        return 'This meal\'s iron is mostly non-heme, without a vitamin-C source, and alongside a potential inhibitor — a less favorable context for absorption.';
      case BioavailabilityLevel.veryLow:
        return 'This meal\'s iron is non-heme with multiple potential inhibitors present and no enhancer — likely a less favorable context for absorption.';
      case BioavailabilityLevel.veryHigh:
        return 'This meal has strong supporting factors for iron availability.';
      case BioavailabilityLevel.unknown:
        return 'There isn\'t enough data on these foods yet to estimate the meal context for iron.';
    }
  }
}
