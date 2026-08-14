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

  // Nullable — the source food may not have a known value (see FoodItem);
  // kept null rather than 0 so daily totals can tell "none logged" apart
  // from "logged, but the amount isn't known".
  final double? magnesium; // mg
  final double? potassium; // mg
  final double? zinc; // mg

  final double? vitaminA; // mcg RAE
  final double? vitaminD; // mcg
  final double? vitaminE; // mg
  final double? vitaminK; // mcg

  // Bioavailability context flags, copied from the source FoodItem at log
  // time (see FoodItem for what these mean and how conservatively they're
  // set) — denormalized the same way magnesium/potassium/zinc are, so a
  // logged meal's context doesn't retroactively change if the catalog does.
  final bool? containsHemeIron;
  final bool? isPlantProtein;
  final bool? isAnimalProtein;
  final bool? isFermented;
  final bool? phytateContext;
  final bool? oxalateContext;
  final bool? isSprouted;

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
    this.magnesium,
    this.potassium,
    this.zinc,
    this.vitaminA,
    this.vitaminD,
    this.vitaminE,
    this.vitaminK,
    this.containsHemeIron,
    this.isPlantProtein,
    this.isAnimalProtein,
    this.isFermented,
    this.phytateContext,
    this.oxalateContext,
    this.isSprouted,
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
      magnesium: item.magnesium == null ? null : item.magnesium! * servings,
      potassium: item.potassium == null ? null : item.potassium! * servings,
      zinc: item.zinc == null ? null : item.zinc! * servings,
      vitaminA: item.vitaminA == null ? null : item.vitaminA! * servings,
      vitaminD: item.vitaminD == null ? null : item.vitaminD! * servings,
      vitaminE: item.vitaminE == null ? null : item.vitaminE! * servings,
      vitaminK: item.vitaminK == null ? null : item.vitaminK! * servings,
      // Presence/absence flags aren't scaled by servings — they describe the
      // food itself, not an amount.
      containsHemeIron: item.containsHemeIron,
      isPlantProtein: item.isPlantProtein,
      isAnimalProtein: item.isAnimalProtein,
      isFermented: item.isFermented,
      phytateContext: item.phytateContext,
      oxalateContext: item.oxalateContext,
      isSprouted: item.isSprouted,
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
        'magnesium': magnesium,
        'potassium': potassium,
        'zinc': zinc,
        'vitamin_a': vitaminA,
        'vitamin_d': vitaminD,
        'vitamin_e': vitaminE,
        'vitamin_k': vitaminK,
        'contains_heme_iron': _boolToDb(containsHemeIron),
        'is_plant_protein': _boolToDb(isPlantProtein),
        'is_animal_protein': _boolToDb(isAnimalProtein),
        'is_fermented': _boolToDb(isFermented),
        'phytate_context': _boolToDb(phytateContext),
        'oxalate_context': _boolToDb(oxalateContext),
        'is_sprouted': _boolToDb(isSprouted),
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
        magnesium: (m['magnesium'] as num?)?.toDouble(),
        potassium: (m['potassium'] as num?)?.toDouble(),
        zinc: (m['zinc'] as num?)?.toDouble(),
        vitaminA: (m['vitamin_a'] as num?)?.toDouble(),
        vitaminD: (m['vitamin_d'] as num?)?.toDouble(),
        vitaminE: (m['vitamin_e'] as num?)?.toDouble(),
        vitaminK: (m['vitamin_k'] as num?)?.toDouble(),
        containsHemeIron: _dbToBool(m['contains_heme_iron']),
        isPlantProtein: _dbToBool(m['is_plant_protein']),
        isAnimalProtein: _dbToBool(m['is_animal_protein']),
        isFermented: _dbToBool(m['is_fermented']),
        phytateContext: _dbToBool(m['phytate_context']),
        oxalateContext: _dbToBool(m['oxalate_context']),
        isSprouted: _dbToBool(m['is_sprouted']),
        dateTime: DateTime.parse(m['date_time'] as String),
      );

  static int? _boolToDb(bool? v) => v == null ? null : (v ? 1 : 0);
  static bool? _dbToBool(Object? v) => v == null ? null : (v as int) != 0;

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
        magnesium: magnesium,
        potassium: potassium,
        zinc: zinc,
        vitaminA: vitaminA,
        vitaminD: vitaminD,
        vitaminE: vitaminE,
        vitaminK: vitaminK,
        containsHemeIron: containsHemeIron,
        isPlantProtein: isPlantProtein,
        isAnimalProtein: isAnimalProtein,
        isFermented: isFermented,
        phytateContext: phytateContext,
        oxalateContext: oxalateContext,
        isSprouted: isSprouted,
        dateTime: dateTime,
      );
}
