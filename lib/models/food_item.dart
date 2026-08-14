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

  // Nullable — unlike the fields above, "not known for this food" is a real
  // and common state here (we only fill these in where a reliable reference
  // value exists), so null (unknown) is kept distinct from 0 (none).
  final double? magnesium; // mg
  final double? potassium; // mg
  final double? zinc; // mg

  // Fat-soluble vitamins — populated only for single-ingredient foods with a
  // well-established, widely-cited reference value (no regional fortification
  // ambiguity, e.g. plain nuts, a plain egg, ghee). Left null for composite
  // dishes and anything where a reliable figure isn't confidently known,
  // rather than estimated. Units follow standard nutrition-label convention:
  // vitaminA in mcg RAE, vitaminD in mcg, vitaminE in mg, vitaminK in mcg.
  final double? vitaminA; // mcg RAE
  final double? vitaminD; // mcg
  final double? vitaminE; // mg
  final double? vitaminK; // mcg

  // Bioavailability context flags — deliberately qualitative (present/absent),
  // never a fabricated milligram value for phytate/oxalate/polyphenols, which
  // this app has no reliable per-food source for. Null means "not assessed",
  // not "no". Only set where the underlying food-science fact is
  // well-established at the whole-food-category level (e.g. meat/poultry/fish
  // contain heme iron; legumes are a recognized high-phytate-context food) —
  // see IndianFoods for exactly which items carry which flags and why.
  final bool? containsHemeIron;
  final bool? isPlantProtein;
  final bool? isAnimalProtein;
  final bool? isFermented;
  final bool? phytateContext; // whole grains/legumes/nuts/seeds — a known iron/zinc inhibitor context
  final bool? oxalateContext; // e.g. spinach — a known calcium/iron inhibitor context

  // Sprouting (germination) is a well-established, distinct preparation
  // method from fermentation — it activates the seed's own phytase enzyme
  // and measurably reduces phytic acid content (e.g. sprouted moong/matki/
  // chana vs. the same legume unsprouted). Only set true for dishes that are
  // explicitly a sprouted preparation (misal, sprouts salads) — never
  // inferred from "contains a legume" alone.
  final bool? isSprouted;

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
    this.isCustom = false,
  });

  /// CSV/table column order used by both export and import.
  static const csvColumns = [
    'name', 'category', 'serving', 'calories', 'protein', 'carbs',
    'fiber', 'fat', 'sugar', 'iron', 'calcium', 'vitaminC', 'caffeine',
    'magnesium', 'potassium', 'zinc', 'vitaminA', 'vitaminD', 'vitaminE', 'vitaminK',
  ];

  List<Object> toCsvRow() => [
        name, category, serving, calories, protein, carbs,
        fiber, fat, sugar, iron, calcium, vitaminC, caffeine,
        magnesium ?? '', potassium ?? '', zinc ?? '',
        vitaminA ?? '', vitaminD ?? '', vitaminE ?? '', vitaminK ?? '',
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
        isCustom: true,
      );

  static int? _boolToDb(bool? v) => v == null ? null : (v ? 1 : 0);
  static bool? _dbToBool(Object? v) => v == null ? null : (v as int) != 0;

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
        isCustom: isCustom,
      );
}
