import 'food_log.dart';

/// How favorable a meal's context appears for a nutrient's bioavailability —
/// a category, never a percentage. See [BioavailabilityEstimate] doc comment
/// for the hard rule this whole feature is built around.
enum BioavailabilityLevel { veryLow, low, moderate, high, veryHigh, unknown }

extension BioavailabilityLevelX on BioavailabilityLevel {
  String get label => switch (this) {
        BioavailabilityLevel.veryLow => 'Very Low',
        BioavailabilityLevel.low => 'Low',
        BioavailabilityLevel.moderate => 'Moderate',
        BioavailabilityLevel.high => 'High',
        BioavailabilityLevel.veryHigh => 'Very High',
        BioavailabilityLevel.unknown => 'Unknown',
      };
}

/// Confidence in *this app's context analysis* — not medical certainty, and
/// not a claim about how well-studied the underlying nutrition science is.
enum EvidenceConfidence { low, medium, high }

extension EvidenceConfidenceX on EvidenceConfidence {
  String get label => switch (this) {
        EvidenceConfidence.low => 'Low',
        EvidenceConfidence.medium => 'Medium',
        EvidenceConfidence.high => 'High',
      };
}

enum NutrientInteractionType { enhancer, inhibitor, contextual }

/// How reliable a piece of food data is, for internal bookkeeping — not
/// shown verbatim to users, but available to widget code that wants to
/// signal "unknown" differently from "known but estimated".
enum DataQuality { verified, sourced, estimated, unknown }

/// A summary of one meal (or a day's worth of logs), built purely from
/// what's already in [FoodLog] — no network calls, no guessed values. Every
/// `contains*` flag is true only if at least one food in [foods] carries
/// that flag; it's false (not unknown) when none do, since "no food in this
/// meal is flagged as X" is itself a known fact, unlike an individual food's
/// unassessed phytate/oxalate content.
class MealContext {
  final List<FoodLog> foods;

  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final double totalFiber;

  final double totalIron;
  final double totalCalcium;
  final double totalZinc;
  final double totalVitaminC;

  final bool containsHemeIronFood;
  final bool containsNonHemeIronFood;
  final bool containsTeaOrCoffee;
  final bool containsVitaminCRichFood;
  final bool containsDietaryFat;
  final bool containsPhytateRichFood;
  final bool containsOxalateRichFood;
  final bool containsFermentedFood;
  final bool containsPlantProteinFood;
  final bool containsAnimalProteinFood;
  final bool containsSproutedFood;

  // Category-derived, not a per-food flag — dairy is a well-established,
  // reasonably-bioavailable calcium source, distinct from oxalate-rich
  // plant sources like spinach.
  final bool containsDairyFood;

  const MealContext({
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.totalFiber,
    required this.totalIron,
    required this.totalCalcium,
    required this.totalZinc,
    required this.totalVitaminC,
    required this.containsHemeIronFood,
    required this.containsNonHemeIronFood,
    required this.containsTeaOrCoffee,
    required this.containsVitaminCRichFood,
    required this.containsDietaryFat,
    required this.containsPhytateRichFood,
    required this.containsOxalateRichFood,
    required this.containsFermentedFood,
    required this.containsPlantProteinFood,
    required this.containsAnimalProteinFood,
    required this.containsSproutedFood,
    required this.containsDairyFood,
  });

  bool get isEmpty => foods.isEmpty;

  /// True only when the meal *does* contain a phytate-context food and every
  /// single one of those foods is also sprouted — sprouting activates the
  /// seed's phytase enzyme and measurably reduces phytic acid content, a
  /// well-established, distinct mechanism from fermentation. A meal with a
  /// mix of sprouted and unsprouted phytate sources is deliberately NOT
  /// treated as mitigated — the unsprouted portion still carries the
  /// inhibitor context.
  bool get phytateFullyMitigatedBySprouting {
    final phytateFoods = foods.where((f) => f.phytateContext == true);
    if (phytateFoods.isEmpty) return false;
    return phytateFoods.every((f) => f.isSprouted == true);
  }
}

/// A meal-context-favorability estimate for one nutrient. Deliberately has
/// no field for "amount absorbed" or "percent absorbed" — this app has no
/// way to measure that, and never claims to. [intake] is what was logged
/// (a real, known number); [level]/[confidence]/explanation are the estimate
/// on top of it.
class BioavailabilityEstimate {
  final String nutrient;
  final double? intake;
  final BioavailabilityLevel level;
  final EvidenceConfidence confidence;
  final List<String> enhancers;
  final List<String> inhibitors;
  final List<String> contextualFactors;
  final List<String> recommendations;
  final String explanation;

  const BioavailabilityEstimate({
    required this.nutrient,
    required this.intake,
    required this.level,
    required this.confidence,
    this.enhancers = const [],
    this.inhibitors = const [],
    this.contextualFactors = const [],
    this.recommendations = const [],
    required this.explanation,
  });
}

/// Builds a [MealContext] from a set of [FoodLog] entries. Pure and
/// synchronous — no I/O, matching the rest of this app's nutrition
/// calculations (see MealQualityScorer for the same pattern).
class MealContextBuilder {
  MealContextBuilder._();

  // A single food needs at least this much vitamin C to count the *meal* as
  // containing a vitamin-C-rich food — matches typical "good source" usage,
  // not an exact RDA-derived cutoff.
  static const double _vitaminCRichThresholdMg = 15;
  static const double _dietaryFatThresholdG = 3;

  static MealContext build(List<FoodLog> foods) {
    if (foods.isEmpty) {
      return const MealContext(
        foods: [],
        totalCalories: 0,
        totalProtein: 0,
        totalFat: 0,
        totalCarbs: 0,
        totalFiber: 0,
        totalIron: 0,
        totalCalcium: 0,
        totalZinc: 0,
        totalVitaminC: 0,
        containsHemeIronFood: false,
        containsNonHemeIronFood: false,
        containsTeaOrCoffee: false,
        containsVitaminCRichFood: false,
        containsDietaryFat: false,
        containsPhytateRichFood: false,
        containsOxalateRichFood: false,
        containsFermentedFood: false,
        containsPlantProteinFood: false,
        containsAnimalProteinFood: false,
        containsSproutedFood: false,
        containsDairyFood: false,
      );
    }

    double sum(double Function(FoodLog) f) => foods.fold(0.0, (s, l) => s + f(l));

    final hemeFoods = foods.where((l) => l.containsHemeIron == true);
    final ironFoods = foods.where((l) => l.iron > 0);
    final nonHemeIronFoods = ironFoods.where((l) => l.containsHemeIron != true);

    return MealContext(
      foods: foods,
      totalCalories: sum((l) => l.calories),
      totalProtein: sum((l) => l.protein),
      totalFat: sum((l) => l.fat),
      totalCarbs: sum((l) => l.carbs),
      totalFiber: sum((l) => l.fiber),
      totalIron: sum((l) => l.iron),
      totalCalcium: sum((l) => l.calcium),
      totalZinc: sum((l) => l.zinc ?? 0),
      totalVitaminC: sum((l) => l.vitaminC),
      containsHemeIronFood: hemeFoods.isNotEmpty,
      containsNonHemeIronFood: nonHemeIronFoods.isNotEmpty,
      containsTeaOrCoffee: foods.any((l) => l.category.toLowerCase() == 'beverages' && l.caffeine > 0),
      containsVitaminCRichFood: foods.any((l) => l.vitaminC >= _vitaminCRichThresholdMg),
      containsDietaryFat: foods.any((l) => l.fat >= _dietaryFatThresholdG),
      containsPhytateRichFood: foods.any((l) => l.phytateContext == true),
      containsOxalateRichFood: foods.any((l) => l.oxalateContext == true),
      containsFermentedFood: foods.any((l) => l.isFermented == true),
      containsPlantProteinFood: foods.any((l) => l.isPlantProtein == true),
      containsAnimalProteinFood: foods.any((l) => l.isAnimalProtein == true),
      containsSproutedFood: foods.any((l) => l.isSprouted == true),
      containsDairyFood: foods.any((l) => l.category.toLowerCase() == 'dairy'),
    );
  }
}
