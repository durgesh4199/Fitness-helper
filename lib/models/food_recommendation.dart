import 'food_item.dart';
import '../providers/nutrition_provider.dart';

/// A nutrient the recommendation engine can target a remaining gap for.
enum RecommendedNutrient { protein, fiber, iron, calcium }

extension RecommendedNutrientX on RecommendedNutrient {
  String get label => switch (this) {
        RecommendedNutrient.protein => 'Protein',
        RecommendedNutrient.fiber => 'Fiber',
        RecommendedNutrient.iron => 'Iron',
        RecommendedNutrient.calcium => 'Calcium',
      };

  String get unit => switch (this) {
        RecommendedNutrient.protein => 'g',
        RecommendedNutrient.fiber => 'g',
        RecommendedNutrient.iron => 'mg',
        RecommendedNutrient.calcium => 'mg',
      };

  double amountIn(FoodItem f) => switch (this) {
        RecommendedNutrient.protein => f.protein,
        RecommendedNutrient.fiber => f.fiber,
        RecommendedNutrient.iron => f.iron,
        RecommendedNutrient.calcium => f.calcium,
      };
}

/// One suggested food for closing a specific nutrient gap.
class FoodRecommendation {
  final FoodItem item;
  final double amount; // how much of the target nutrient one serving provides
  final double fillPercent; // 0-1, how much of the remaining gap this closes

  const FoodRecommendation({
    required this.item,
    required this.amount,
    required this.fillPercent,
  });
}

/// Suggests foods from the catalog to help close today's remaining nutrient
/// gaps, filtered so they won't spike a diabetic user's blood sugar and
/// aren't oil-heavy dishes.
class FoodRecommendationEngine {
  FoodRecommendationEngine._();

  /// A food is considered "oily" if fat alone accounts for more than this
  /// share of its calories — a proxy for fried/oil-heavy dishes since the
  /// catalog has no explicit oiliness tag. This also flags some naturally
  /// fatty whole foods (e.g. milk, paneer, boiled egg) as a known trade-off
  /// of using a macro-only heuristic.
  static const double _oilyFatCaloriePercent = 0.40;

  /// A food's diabetic-adjusted spike impact above this is excluded outright
  /// when recommending for a diabetic user (calibrated against the built-in
  /// catalog: excludes sweets, mango, mass-gainer shakes; keeps dals,
  /// legumes, protein shakes, and low-sugar fruit).
  static const double _diabeticSafeSpikeThreshold = 30.0;

  static bool _isOily(FoodItem f) {
    if (f.calories <= 0) return false;
    return (f.fat * 9 / f.calories) > _oilyFatCaloriePercent;
  }

  static double _spike(FoodItem f, {bool diabetic = false}) => NutritionProvider.spikeImpact(
        sugar: f.sugar,
        carbs: f.carbs,
        fiber: f.fiber,
        diabetic: diabetic,
      );

  /// Top picks to help close the remaining gap for [nutrient], filtered for
  /// sugar-safety (stricter if [diabetic]) and oiliness, and roughly fitted
  /// to [remainingCalories] so a single suggestion doesn't blow the day's
  /// calorie budget.
  static List<FoodRecommendation> recommendFor({
    required RecommendedNutrient nutrient,
    required double remainingAmount,
    required double remainingCalories,
    required List<FoodItem> catalog,
    required bool diabetic,
    int limit = 3,
  }) {
    if (remainingAmount <= 0) return const [];

    final candidates = catalog.where((f) {
      if (nutrient.amountIn(f) <= 0) return false;
      if (_isOily(f)) return false;
      if (f.calories > remainingCalories + 150) return false;
      if (diabetic && _spike(f, diabetic: true) > _diabeticSafeSpikeThreshold) return false;
      return true;
    }).toList();

    candidates.sort((a, b) {
      final fillA = (nutrient.amountIn(a) / remainingAmount).clamp(0.0, 1.0);
      final fillB = (nutrient.amountIn(b) / remainingAmount).clamp(0.0, 1.0);
      final cmp = fillB.compareTo(fillA);
      if (cmp != 0) return cmp;
      return _spike(a).compareTo(_spike(b)); // tiebreak: lower sugar-spike first
    });

    return candidates.take(limit).map((f) {
      final amount = nutrient.amountIn(f);
      return FoodRecommendation(
        item: f,
        amount: amount,
        fillPercent: (amount / remainingAmount).clamp(0.0, 1.0),
      );
    }).toList();
  }
}
