/// A food from the reference database, with nutrition per one serving.
/// Built-in foods have [id] == null; foods the user imported/added have a
/// database [id] and [isCustom] == true.
class FoodItem {
  final int? id;
  final String name;
  final String category;
  final String serving; // human description of one serving, e.g. "1 bowl (150g)"
  final double calories; // kcal
  final double protein; // g
  final double carbs; // g
  final double fiber; // g
  final double fat; // g
  final double sugar; // g
  final double iron; // mg
  final double calcium; // mg
  final double vitaminC; // mg
  final double caffeine; // mg
  final bool isCustom;

  const FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fiber,
    required this.fat,
    this.sugar = 0,
    this.iron = 0,
    this.calcium = 0,
    this.vitaminC = 0,
    this.caffeine = 0,
    this.isCustom = false,
  });

  /// CSV/table column order used by both export and import.
  static const csvColumns = [
    'name', 'category', 'serving', 'calories', 'protein', 'carbs',
    'fiber', 'fat', 'sugar', 'iron', 'calcium', 'vitaminC', 'caffeine',
  ];

  List<Object> toCsvRow() => [
        name, category, serving, calories, protein, carbs,
        fiber, fat, sugar, iron, calcium, vitaminC, caffeine,
      ];

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'serving': serving,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fiber': fiber,
        'fat': fat,
        'sugar': sugar,
        'iron': iron,
        'calcium': calcium,
        'vitamin_c': vitaminC,
        'caffeine': caffeine,
      };

  factory FoodItem.fromMap(Map<String, Object?> m) => FoodItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        serving: m['serving'] as String,
        calories: (m['calories'] as num).toDouble(),
        protein: (m['protein'] as num).toDouble(),
        carbs: (m['carbs'] as num).toDouble(),
        fiber: (m['fiber'] as num).toDouble(),
        fat: (m['fat'] as num).toDouble(),
        sugar: (m['sugar'] as num?)?.toDouble() ?? 0,
        iron: (m['iron'] as num?)?.toDouble() ?? 0,
        calcium: (m['calcium'] as num?)?.toDouble() ?? 0,
        vitaminC: (m['vitamin_c'] as num?)?.toDouble() ?? 0,
        caffeine: (m['caffeine'] as num?)?.toDouble() ?? 0,
        isCustom: true,
      );

  FoodItem copyWith({int? id}) => FoodItem(
        id: id ?? this.id,
        name: name,
        category: category,
        serving: serving,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fiber: fiber,
        fat: fat,
        sugar: sugar,
        iron: iron,
        calcium: calcium,
        vitaminC: vitaminC,
        caffeine: caffeine,
        isCustom: isCustom,
      );
}
