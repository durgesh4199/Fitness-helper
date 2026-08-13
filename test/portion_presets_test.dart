import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/food_item.dart';
import 'package:fitness_tracker/models/portion_presets.dart';

const _riceWithGrams = FoodItem(
  name: 'Plain Rice',
  category: 'Grains & Breads',
  serving: '1 cup cooked (150g)',
  calories: 205,
  protein: 4,
  carbs: 45,
  fiber: 0.6,
  fat: 0.4,
);

const _samosaNoGrams = FoodItem(
  name: 'Samosa',
  category: 'Snacks',
  serving: '1 piece',
  calories: 260,
  protein: 4,
  carbs: 30,
  fiber: 2,
  fat: 14,
);

void main() {
  group('PortionSize', () {
    test('medium is always a 1.0x multiplier (matches the catalog serving)', () {
      expect(PortionSize.medium.multiplier, 1.0);
    });

    test('small is smaller and large is bigger than medium', () {
      expect(PortionSize.small.multiplier, lessThan(PortionSize.medium.multiplier));
      expect(PortionSize.large.multiplier, greaterThan(PortionSize.medium.multiplier));
    });
  });

  group('PortionPresets.labelFor', () {
    test('derives a scaled gram label when the serving states a weight', () {
      expect(PortionPresets.labelFor(_riceWithGrams, PortionSize.medium), '150g');
      expect(PortionPresets.labelFor(_riceWithGrams, PortionSize.small), '113g');
      expect(PortionPresets.labelFor(_riceWithGrams, PortionSize.large), '225g');
    });

    test('falls back to the size name when no weight is stated', () {
      expect(PortionPresets.labelFor(_samosaNoGrams, PortionSize.medium), 'Medium');
      expect(PortionPresets.labelFor(_samosaNoGrams, PortionSize.small), 'Small');
    });
  });
}
