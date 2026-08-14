import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/models/food_log.dart';

FoodLog _log({
  String name = 'Food',
  String category = 'Grains & Breads',
  double iron = 0,
  double vitaminC = 0,
  double fat = 0,
  double caffeine = 0,
  bool? containsHemeIron,
  bool? isPlantProtein,
  bool? isAnimalProtein,
  bool? isFermented,
  bool? phytateContext,
  bool? oxalateContext,
}) {
  return FoodLog(
    name: name,
    category: category,
    meal: 'Lunch',
    servings: 1,
    calories: 100,
    protein: 5,
    carbs: 10,
    fiber: 2,
    fat: fat,
    sugar: 0,
    iron: iron,
    calcium: 0,
    vitaminC: vitaminC,
    caffeine: caffeine,
    containsHemeIron: containsHemeIron,
    isPlantProtein: isPlantProtein,
    isAnimalProtein: isAnimalProtein,
    isFermented: isFermented,
    phytateContext: phytateContext,
    oxalateContext: oxalateContext,
    dateTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('MealContextBuilder.build', () {
    test('an empty meal produces an empty, all-false context', () {
      final ctx = MealContextBuilder.build(const []);
      expect(ctx.isEmpty, isTrue);
      expect(ctx.totalIron, 0);
      expect(ctx.containsHemeIronFood, isFalse);
      expect(ctx.containsNonHemeIronFood, isFalse);
    });

    test('sums nutrition totals across all logged foods', () {
      final ctx = MealContextBuilder.build([
        _log(iron: 2, vitaminC: 10),
        _log(iron: 1.5, vitaminC: 5),
      ]);
      expect(ctx.totalIron, closeTo(3.5, 0.001));
      expect(ctx.totalVitaminC, closeTo(15, 0.001));
    });

    test('containsHemeIronFood is true only when a food is explicitly flagged', () {
      final ctx = MealContextBuilder.build([_log(iron: 2, containsHemeIron: true)]);
      expect(ctx.containsHemeIronFood, isTrue);
      expect(ctx.containsNonHemeIronFood, isFalse);
    });

    test('a food with iron but no heme flag counts as non-heme (heme requires the explicit flag)', () {
      final ctx = MealContextBuilder.build([_log(iron: 2)]);
      expect(ctx.containsHemeIronFood, isFalse);
      expect(ctx.containsNonHemeIronFood, isTrue);
    });

    test('vitamin-C-rich detection uses a threshold, not any nonzero amount', () {
      final low = MealContextBuilder.build([_log(vitaminC: 5)]);
      final high = MealContextBuilder.build([_log(vitaminC: 20)]);
      expect(low.containsVitaminCRichFood, isFalse);
      expect(high.containsVitaminCRichFood, isTrue);
    });

    test('tea/coffee context requires both Beverages category and caffeine', () {
      final tea = MealContextBuilder.build([_log(category: 'Beverages', caffeine: 40)]);
      final juice = MealContextBuilder.build([_log(category: 'Beverages', caffeine: 0)]);
      expect(tea.containsTeaOrCoffee, isTrue);
      expect(juice.containsTeaOrCoffee, isFalse);
    });

    test('phytate/oxalate context flags only trigger on an explicit true, not null', () {
      final unknown = MealContextBuilder.build([_log(iron: 1)]);
      final known = MealContextBuilder.build([_log(iron: 1, phytateContext: true, oxalateContext: true)]);
      expect(unknown.containsPhytateRichFood, isFalse);
      expect(unknown.containsOxalateRichFood, isFalse);
      expect(known.containsPhytateRichFood, isTrue);
      expect(known.containsOxalateRichFood, isTrue);
    });

    test('containsDairyFood is derived from category alone', () {
      final dairy = MealContextBuilder.build([_log(category: 'Dairy')]);
      final nonDairy = MealContextBuilder.build([_log(category: 'Vegetables')]);
      expect(dairy.containsDairyFood, isTrue);
      expect(nonDairy.containsDairyFood, isFalse);
    });
  });
}
