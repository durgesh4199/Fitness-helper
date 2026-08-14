import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/indian_foods.dart';
import 'package:fitness_tracker/models/regional_foods.dart';

void main() {
  group('IndianFoods.items (curated + regional catalog)', () {
    test('combines the curated list with the full regional list', () {
      expect(IndianFoods.items.length, greaterThanOrEqualTo(2000));
      expect(IndianFoods.items.length, RegionalFoods.items.length + 62);
    });

    test('has no duplicate names', () {
      final names = IndianFoods.items.map((f) => f.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('every item resolves to a known category, not the "Other" fallback', () {
      final knownNames = IndianFoods.categories.map((c) => c.name.toLowerCase()).toSet();
      for (final item in IndianFoods.items) {
        expect(
          knownNames.contains(item.category.toLowerCase()),
          isTrue,
          reason: '${item.name} has unrecognized category "${item.category}"',
        );
      }
    });

    test('newly added categories are present with icons/colors', () {
      for (final name in ['Salads', 'Nuts & Seeds', 'Soups']) {
        expect(IndianFoods.categories.any((c) => c.name == name), isTrue, reason: name);
      }
    });

    test('never fabricates magnesium/potassium/zinc for regional items (left null)', () {
      for (final item in RegionalFoods.items) {
        expect(item.magnesium, isNull, reason: item.name);
        expect(item.potassium, isNull, reason: item.name);
        expect(item.zinc, isNull, reason: item.name);
      }
    });

    test('a known meat dish carries heme iron but a known egg dish does not', () {
      final chicken = RegionalFoods.items.firstWhere((f) => f.name == 'Chicken Chukka (Chettinad Style)');
      final egg = RegionalFoods.items.firstWhere((f) => f.name == 'Egg Bhurji');
      expect(chicken.containsHemeIron, isTrue);
      expect(egg.containsHemeIron, isNull);
      expect(egg.isAnimalProtein, isTrue);
    });

    test('plant milks filed under "Dairy" are not asserted as animal protein', () {
      final soyMilk = RegionalFoods.items.firstWhere((f) => f.name == 'Soy Milk');
      expect(soyMilk.isAnimalProtein, isNull);
      expect(soyMilk.isPlantProtein, isTrue);
    });

    test('a spinach-based dish carries oxalate context regardless of category', () {
      final palakChapati = RegionalFoods.items.firstWhere((f) => f.name == 'Palak Chapati');
      expect(palakChapati.oxalateContext, isTrue);
    });

    test('a fermented batter dish is flagged fermented, not phytate-context', () {
      final dosa = RegionalFoods.items.firstWhere((f) => f.name == 'Nachni Dosa');
      expect(dosa.isFermented, isTrue);
      expect(dosa.phytateContext, isNull);
    });

    test('a sprouted-preparation dish is flagged isSprouted, and Brussels Sprouts is not', () {
      final misal = RegionalFoods.items.firstWhere((f) => f.name == 'Misal (Spicy Sprouts Curry)');
      expect(misal.isSprouted, isTrue);
      final brussels = RegionalFoods.items.firstWhere((f) => f.name == 'Brussels Sprouts');
      expect(brussels.isSprouted, isNull);
    });
  });
}
