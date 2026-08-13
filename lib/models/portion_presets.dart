import 'food_item.dart';

/// Named portion sizes, stored centrally here (not hardcoded in a screen)
/// so any log-food UI can reuse the same definitions. Multipliers apply on
/// top of the catalog's authored serving — "Medium" always equals the
/// catalog's stated serving (1.0x), matching existing behavior; "Small"/
/// "Large" scale it down/up by a fixed, food-agnostic ratio.
enum PortionSize { small, medium, large }

extension PortionSizeX on PortionSize {
  String get label => switch (this) {
        PortionSize.small => 'Small',
        PortionSize.medium => 'Medium',
        PortionSize.large => 'Large',
      };

  double get multiplier => switch (this) {
        PortionSize.small => 0.75,
        PortionSize.medium => 1.0,
        PortionSize.large => 1.5,
      };
}

class PortionPresets {
  PortionPresets._();

  static const all = PortionSize.values;

  /// Extracts a gram (or ml) weight embedded in a serving description like
  /// "1 bowl (150g)" or "1 glass (250ml)" — returns null when the serving
  /// isn't described in grams/ml (e.g. "1 piece", "5 pieces"), since we
  /// won't guess a weight that isn't stated.
  static int? _baseGrams(FoodItem food) {
    final match = RegExp(r'\((\d+)\s*(g|ml)\)').firstMatch(food.serving);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String? _unit(FoodItem food) {
    final match = RegExp(r'\((\d+)\s*(g|ml)\)').firstMatch(food.serving);
    return match?.group(2);
  }

  /// A short label for [size] applied to [food] — a gram/ml amount when the
  /// base serving states one (e.g. "113g"), otherwise just the size name.
  static String labelFor(FoodItem food, PortionSize size) {
    final base = _baseGrams(food);
    if (base == null) return size.label;
    final unit = _unit(food) ?? 'g';
    final scaled = (base * size.multiplier).round();
    return '$scaled$unit';
  }
}
