import 'bioavailability.dart';

/// Estimates how favorable a meal's context looks for a fat-soluble
/// vitamin's bioavailability — never how much was actually absorbed.
///
/// This app tracks vitaminA/D/E/K for only a small, deliberately curated set
/// of single-ingredient foods (see IndianFoods/RegionalFoods) — coverage is
/// intentionally narrow rather than guessed for composite dishes. This
/// analyzer itself relies on exactly one well-established mechanism: vitamins
/// A, D, E, and K all require dietary fat to be absorbed efficiently (they're
/// fat-soluble, not water-soluble), so a meal containing some dietary fat is
/// a more favorable context than one without. There is no established
/// inhibitor tracked for these vitamins in this app, so unlike Iron/Zinc/
/// Calcium, this analyzer never reports a "low" or "very low" level — the
/// absence of fat means "less enhanced," not "actively inhibited," and this
/// app has no evidence to claim the latter.
class FatSolubleVitaminAnalyzer {
  FatSolubleVitaminAnalyzer._();

  /// One shared entry point for all four fat-soluble vitamins — the
  /// underlying logic (does this meal contain dietary fat?) is identical for
  /// each, so a single nutrient-parameterized analyzer avoids four
  /// near-duplicate classes. [nutrientLabel] should be the display name,
  /// e.g. "Vitamin A".
  ///
  /// Returns null when the meal has no intake of this vitamin — nothing to
  /// analyze, not a fake result. [intakeUnit] should match how the source
  /// data is stored — 'mcg' for A/D/K, 'mg' for E (see FoodItem).
  static BioavailabilityEstimate? analyze(
    MealContext meal, {
    required String nutrientLabel,
    required double intake,
    String intakeUnit = 'mcg',
  }) {
    if (meal.isEmpty || intake <= 0) return null;

    final enhancers = <String>[];
    final recommendations = <String>[];

    final level = meal.containsDietaryFat ? BioavailabilityLevel.high : BioavailabilityLevel.moderate;
    if (meal.containsDietaryFat) {
      enhancers.add('Dietary fat present in this meal');
    } else {
      recommendations.add(
        '$nutrientLabel is fat-soluble — pairing this food with a source of dietary fat (e.g. ghee, nuts, oil) may support absorption.',
      );
    }

    return BioavailabilityEstimate(
      nutrient: nutrientLabel,
      intake: intake,
      intakeUnit: intakeUnit,
      level: level,
      // Fixed at medium, not derived from a per-food assessment ratio like
      // Iron/Zinc/Calcium: this analyzer tracks exactly one mechanism
      // (dietary fat), so it's neither richly cross-validated (high) nor
      // genuinely missing data (low) — it's a narrower, single-factor read.
      confidence: EvidenceConfidence.medium,
      enhancers: enhancers,
      recommendations: recommendations,
      explanation: _explanation(nutrientLabel, level),
    );
  }

  static String _explanation(String nutrientLabel, BioavailabilityLevel level) {
    if (level == BioavailabilityLevel.high) {
      return '$nutrientLabel is fat-soluble and this meal contains dietary fat — a favorable context for absorption.';
    }
    return '$nutrientLabel is fat-soluble; this meal doesn\'t contain much dietary fat alongside it, which may mean less favorable absorption than if it did.';
  }
}
