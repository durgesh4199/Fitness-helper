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

/// Two foods suggested together because eaten as a pair they close more of
/// today's remaining nutrient gaps than either alone — meals are usually
/// combinations (dal + roti, curd + oats), not single ingredients.
class FoodComboRecommendation {
  final FoodItem first;
  final FoodItem second;

  /// Combined contribution per nutrient (first + second), for every
  /// nutrient that still has a remaining gap.
  final Map<RecommendedNutrient, double> combinedAmounts;

  const FoodComboRecommendation({
    required this.first,
    required this.second,
    required this.combinedAmounts,
  });

  double get combinedCalories => first.calories + second.calories;
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

  /// Suggests food pairs that, eaten together, close the most of today's
  /// remaining gaps across every nutrient in [remaining] (not just one) —
  /// e.g. a protein-heavy food paired with a fiber-heavy one. Same
  /// sugar-safety/oiliness/calorie-budget filtering as [recommendFor].
  static List<FoodComboRecommendation> recommendCombinations({
    required Map<RecommendedNutrient, double> remaining,
    required double remainingCalories,
    required List<FoodItem> catalog,
    required bool diabetic,
    int limit = 2,
  }) {
    final activeGaps = remaining.entries.where((e) => e.value > 0).toList();
    if (activeGaps.isEmpty) return const [];

    final candidates = catalog.where((f) {
      if (_isOily(f)) return false;
      if (diabetic && _spike(f, diabetic: true) > _diabeticSafeSpikeThreshold) return false;
      return activeGaps.any((e) => e.key.amountIn(f) > 0); // contributes to at least one gap
    }).toList();
    if (candidates.length < 2) return const [];

    double gapScore(FoodItem f) {
      var s = 0.0;
      for (final e in activeGaps) {
        s += (e.key.amountIn(f) / e.value).clamp(0.0, 1.0);
      }
      return s;
    }

    // Keep pairing cheap: only pair among the individually-strongest picks.
    final shortlist = [...candidates]..sort((a, b) => gapScore(b).compareTo(gapScore(a)));
    final pool = shortlist.take(10).toList();

    final combos = <FoodComboRecommendation>[];
    for (var i = 0; i < pool.length; i++) {
      for (var j = i + 1; j < pool.length; j++) {
        final a = pool[i], b = pool[j];
        if (a.calories + b.calories > remainingCalories + 150) continue;
        combos.add(FoodComboRecommendation(
          first: a,
          second: b,
          combinedAmounts: {for (final e in activeGaps) e.key: e.key.amountIn(a) + e.key.amountIn(b)},
        ));
      }
    }

    double comboScore(FoodComboRecommendation c) {
      var s = 0.0;
      for (final e in activeGaps) {
        s += (c.combinedAmounts[e.key]! / e.value).clamp(0.0, 1.0);
      }
      return s;
    }

    combos.sort((a, b) => comboScore(b).compareTo(comboScore(a)));
    return combos.take(limit).toList();
  }
}
