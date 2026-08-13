import 'food_log.dart';

/// One neutral factor considered in a meal's quality score. Deliberately
/// small and matched to what the app actually measures — no sodium (not
/// tracked) and no "added sugar" claim (we only track total sugar).
enum MealQualityFactor { protein, fiber, vegetablesOrFruit, sugar, calories }

extension MealQualityFactorX on MealQualityFactor {
  String get label => switch (this) {
        MealQualityFactor.protein => 'Protein',
        MealQualityFactor.fiber => 'Fiber',
        MealQualityFactor.vegetablesOrFruit => 'Vegetables/fruit',
        MealQualityFactor.sugar => 'Sugar',
        MealQualityFactor.calories => 'Portion size',
      };
}

/// A meal's quality breakdown — a transparent, deterministic checklist, not
/// a judgment of whether specific foods are "good" or "bad". Each factor is
/// simply met or not met against a fixed, documented threshold.
class MealQualityResult {
  final int score; // 0-100, percentage of factors met
  final Map<MealQualityFactor, bool> checks;

  const MealQualityResult({required this.score, required this.checks});
}

class MealQualityScorer {
  MealQualityScorer._();

  // Thresholds are calibrated to a single meal (roughly a quarter to a
  // third of a day's targets), not a full day's intake.
  static const double _proteinGoodMin = 12; // g
  static const double _fiberGoodMin = 4; // g
  static const double _sugarGoodMax = 12; // g
  static const double _caloriesGoodMax = 800; // kcal — flags unusually large meals

  static const _vegFruitCategories = {'vegetables', 'fruits'};

  static MealQualityResult score(List<FoodLog> mealLogs) {
    if (mealLogs.isEmpty) {
      return const MealQualityResult(score: 0, checks: {});
    }

    final totalProtein = mealLogs.fold<double>(0, (s, l) => s + l.protein);
    final totalFiber = mealLogs.fold<double>(0, (s, l) => s + l.fiber);
    final totalSugar = mealLogs.fold<double>(0, (s, l) => s + l.sugar);
    final totalCalories = mealLogs.fold<double>(0, (s, l) => s + l.calories);
    final hasVegOrFruit = mealLogs.any((l) => _vegFruitCategories.contains(l.category.toLowerCase()));

    final checks = <MealQualityFactor, bool>{
      MealQualityFactor.protein: totalProtein >= _proteinGoodMin,
      MealQualityFactor.fiber: totalFiber >= _fiberGoodMin,
      MealQualityFactor.vegetablesOrFruit: hasVegOrFruit,
      MealQualityFactor.sugar: totalSugar <= _sugarGoodMax,
      MealQualityFactor.calories: totalCalories <= _caloriesGoodMax,
    };

    final met = checks.values.where((v) => v).length;
    final score = ((met / checks.length) * 100).round();
    return MealQualityResult(score: score, checks: checks);
  }
}
