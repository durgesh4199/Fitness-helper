import 'food_item.dart';

/// A food the user actually ate: stores the *total* nutrition for the logged
/// amount (servings x per-serving values) so it's independent of later changes
/// to the reference database.
class FoodLog {
  final int? id;
  final String name;
  final String category;
  final String meal; // Breakfast | Lunch | Snacks | Dinner
  final double servings;
  final double calories;
  final double protein;
  final double carbs;
  final double fiber;
  final double fat;
  final double sugar;
  final double iron;
  final double calcium;
  final double vitaminC;
  final double caffeine;
  final DateTime dateTime;

  const FoodLog({
    this.id,
    required this.name,
    required this.category,
    required this.meal,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fiber,
    required this.fat,
    required this.sugar,
    required this.iron,
    required this.calcium,
    required this.vitaminC,
    required this.caffeine,
    required this.dateTime,
  });

  factory FoodLog.fromItem(FoodItem item, double servings, String meal, DateTime when) {
    return FoodLog(
      name: item.name,
      category: item.category,
      meal: meal,
      servings: servings,
      calories: item.calories * servings,
      protein: item.protein * servings,
      carbs: item.carbs * servings,
      fiber: item.fiber * servings,
      fat: item.fat * servings,
      sugar: item.sugar * servings,
      iron: item.iron * servings,
      calcium: item.calcium * servings,
      vitaminC: item.vitaminC * servings,
      caffeine: item.caffeine * servings,
      dateTime: when,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'meal': meal,
        'servings': servings,
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
        'date_time': dateTime.toIso8601String(),
      };

  factory FoodLog.fromMap(Map<String, Object?> m) => FoodLog(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        meal: m['meal'] as String,
        servings: (m['servings'] as num).toDouble(),
        calories: (m['calories'] as num).toDouble(),
        protein: (m['protein'] as num).toDouble(),
        carbs: (m['carbs'] as num).toDouble(),
        fiber: (m['fiber'] as num).toDouble(),
        fat: (m['fat'] as num).toDouble(),
        sugar: (m['sugar'] as num?)?.toDouble() ?? 0,
        iron: (m['iron'] as num).toDouble(),
        calcium: (m['calcium'] as num).toDouble(),
        vitaminC: (m['vitamin_c'] as num).toDouble(),
        caffeine: (m['caffeine'] as num?)?.toDouble() ?? 0,
        dateTime: DateTime.parse(m['date_time'] as String),
      );

  FoodLog copyWith({int? id}) => FoodLog(
        id: id ?? this.id,
        name: name,
        category: category,
        meal: meal,
        servings: servings,
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
        dateTime: dateTime,
      );
}
