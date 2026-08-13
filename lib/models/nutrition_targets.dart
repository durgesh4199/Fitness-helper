import 'dart:math' as math;
import '../providers/user_provider.dart';

/// Personalized daily nutrition targets computed from the user's body metrics
/// (weight, height, age, sex, activity level, and weight goal).
///
/// - Calories: Mifflin-St Jeor BMR x activity factor, adjusted for the weight
///   goal (deficit to lose, surplus to gain).
/// - Protein: grams per kg bodyweight, scaled by activity.
/// - Fat: ~27% of calories; Carbs: the remainder.
/// - Fiber: ~14 g per 1000 kcal.
/// - Sugar: WHO free-sugar guidance (<10% of energy).
/// - Water: ~35 ml per kg.
/// - Calcium / Iron / Vitamin C / Magnesium / Potassium / Zinc: published
///   RDA/AI guideline values by age and sex (NIH/IOM), not derived from the
///   user's own data.
class NutritionTargets {
  final int calories;
  final int protein; // g
  final int carbs; // g
  final int fat; // g
  final int fiber; // g
  final int sugar; // g (soft daily limit)
  final int waterMl;
  final int calcium; // mg
  final int iron; // mg
  final int vitaminC; // mg
  final int magnesium; // mg
  final int potassium; // mg
  final int zinc; // mg
  final String goalLabel; // "Lose weight" | "Maintain" | "Gain weight"

  const NutritionTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.waterMl,
    required this.calcium,
    required this.iron,
    required this.vitaminC,
    required this.magnesium,
    required this.potassium,
    required this.zinc,
    required this.goalLabel,
  });

  factory NutritionTargets.forUser(UserProvider u) {
    return NutritionTargets.compute(
      weightKg: u.weightKg,
      heightCm: u.heightCm,
      age: u.age,
      sex: u.sex,
      activity: u.activity,
      goalWeightKg: u.goalWeightKg,
    );
  }

  factory NutritionTargets.compute({
    required double weightKg,
    required double heightCm,
    required int age,
    required Sex sex,
    required ActivityLevel activity,
    required double goalWeightKg,
  }) {
    // Mifflin-St Jeor basal metabolic rate.
    final bmr = 10 * weightKg +
        6.25 * heightCm -
        5 * age +
        (sex == Sex.male ? 5 : -161);
    final tdee = bmr * activity.factor;

    // Adjust for weight goal (~0.4 kg/week ≈ 400 kcal/day).
    final diff = goalWeightKg - weightKg;
    String goalLabel;
    double calories;
    if (diff <= -1) {
      goalLabel = 'Lose weight';
      calories = tdee - 400;
    } else if (diff >= 1) {
      goalLabel = 'Gain weight';
      calories = tdee + 300;
    } else {
      goalLabel = 'Maintain';
      calories = tdee;
    }
    // Never recommend below the resting metabolic rate.
    calories = math.max(calories, bmr);

    final protein = (weightKg * activity.proteinPerKg).round();
    final fat = (calories * 0.27 / 9).round();
    final proteinCals = protein * 4;
    final fatCals = fat * 9;
    final carbs = math.max(0, (calories - proteinCals - fatCals) / 4).round();
    final fiber = (calories / 1000 * 14).round();
    final sugar = (calories * 0.10 / 4).round(); // <10% energy from free sugars
    final waterMl = (weightKg * 35).round();

    // RDA micros by age & sex.
    final calcium = age <= 18
        ? 1300
        : age >= 51
            ? 1200
            : 1000;
    final iron = (sex == Sex.female && age >= 19 && age <= 50) ? 18 : 8;
    final vitaminC = sex == Sex.male ? 90 : 75;

    // Published adult RDA (magnesium, zinc) / AI (potassium) — NIH Office
    // of Dietary Supplements guideline values, not per-user calculations.
    final magnesium = age <= 18
        ? (sex == Sex.male ? 410 : 360)
        : (sex == Sex.male ? (age >= 31 ? 420 : 400) : (age >= 31 ? 320 : 310));
    final potassium = sex == Sex.male ? 3400 : 2600;
    final zinc = sex == Sex.male ? 11 : 8;

    return NutritionTargets(
      calories: calories.round(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      waterMl: waterMl,
      calcium: calcium,
      iron: iron,
      vitaminC: vitaminC,
      magnesium: magnesium,
      potassium: potassium,
      zinc: zinc,
      goalLabel: goalLabel,
    );
  }
}
