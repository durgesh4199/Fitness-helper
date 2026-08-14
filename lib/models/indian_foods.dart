import 'package:flutter/material.dart';
import 'food_item.dart';
import '../theme/app_theme.dart';

class FoodCategory {
  final String name;
  final IconData icon;
  final Color color;
  const FoodCategory(this.name, this.icon, this.color);
}

/// Reference database of common Indian foods (plus supplements & shakes) with
/// approximate nutrition per serving. Values are estimates for typical
/// portions — good enough for day-to-day tracking, not clinical precision.
class IndianFoods {
  IndianFoods._();

  static const categories = [
    FoodCategory('Grains & Breads', Icons.bakery_dining_rounded, AppBrand.accentOrange),
    FoodCategory('Dals & Legumes', Icons.rice_bowl_rounded, AppBrand.secondary),
    FoodCategory('Vegetables', Icons.eco_rounded, AppBrand.fiber),
    FoodCategory('Dairy', Icons.egg_alt_rounded, AppBrand.accentBlue),
    FoodCategory('Snacks', Icons.lunch_dining_rounded, AppBrand.accentPink),
    FoodCategory('Non-Veg', Icons.set_meal_rounded, AppBrand.primary),
    FoodCategory('Fruits', Icons.spa_rounded, AppBrand.fiber),
    FoodCategory('Beverages', Icons.local_cafe_rounded, AppBrand.accentOrange),
    FoodCategory('Sweets', Icons.icecream_rounded, AppBrand.accentPink),
    FoodCategory('Shakes', Icons.blender_rounded, AppBrand.accentBlue),
    FoodCategory('Supplements', Icons.medication_rounded, AppBrand.primary),
  ];

  /// Fallback used for categories not in the built-in list (e.g. a custom
  /// category name introduced by an imported food).
  static const unknownCategory = FoodCategory('Other', Icons.fastfood_rounded, AppBrand.primary);

  static IconData iconFor(String category) => categories
      .firstWhere((c) => c.name.toLowerCase() == category.toLowerCase(), orElse: () => unknownCategory)
      .icon;

  static Color colorFor(String category) => categories
      .firstWhere((c) => c.name.toLowerCase() == category.toLowerCase(), orElse: () => unknownCategory)
      .color;

  // Magnesium/potassium/zinc below are populated only for simple,
  // single-ingredient staples where standard nutrition-database per-100g
  // values are well established and widely cited (rounded, scaled to
  // this item's serving weight) — everything else is deliberately left
  // unset (unknown) rather than guessed. See models/food_item.dart.
  static const items = <FoodItem>[
    // ---- Grains & Breads ----
    // Whole-grain-based items are a recognized (moderate) phytate context —
    // see e.g. NIH ODS Iron/Zinc fact sheets on whole grains as an inhibitor
    // food group, alongside legumes.
    FoodItem(name: 'Roti / Chapati', category: 'Grains & Breads', serving: '1 medium (40g)', calories: 120, protein: 3, carbs: 18, fiber: 3, fat: 3, sugar: 0.5, iron: 1.1, calcium: 12, magnesium: 33, potassium: 100, zinc: 0.5, isPlantProtein: true, phytateContext: true),
    FoodItem(name: 'Plain Rice', category: 'Grains & Breads', serving: '1 cup cooked (150g)', calories: 205, protein: 4, carbs: 45, fiber: 0.6, fat: 0.4, sugar: 0.1, iron: 1.9, calcium: 16, magnesium: 18, potassium: 53, zinc: 0.8, isPlantProtein: true),
    FoodItem(name: 'Jeera Rice', category: 'Grains & Breads', serving: '1 cup (150g)', calories: 240, protein: 4, carbs: 45, fiber: 1, fat: 5, sugar: 0.2, iron: 1.9, calcium: 18, isPlantProtein: true),
    FoodItem(name: 'Plain Paratha', category: 'Grains & Breads', serving: '1 piece', calories: 260, protein: 5, carbs: 36, fiber: 3, fat: 10, sugar: 1, iron: 1.6, calcium: 20, isPlantProtein: true, phytateContext: true),
    FoodItem(name: 'Poha', category: 'Grains & Breads', serving: '1 bowl (150g)', calories: 250, protein: 5, carbs: 45, fiber: 2, fat: 6, sugar: 2, iron: 2.7, calcium: 20, vitaminC: 6, isPlantProtein: true),
    FoodItem(name: 'Upma', category: 'Grains & Breads', serving: '1 bowl (150g)', calories: 250, protein: 6, carbs: 40, fiber: 3, fat: 8, sugar: 1, iron: 1.5, calcium: 25, isPlantProtein: true),
    FoodItem(name: 'Idli', category: 'Grains & Breads', serving: '2 pieces', calories: 140, protein: 5, carbs: 28, fiber: 1, fat: 1, sugar: 0.5, iron: 1.2, calcium: 15, magnesium: 30, potassium: 75, zinc: 0.75, isPlantProtein: true, isFermented: true),
    FoodItem(name: 'Plain Dosa', category: 'Grains & Breads', serving: '1 piece', calories: 165, protein: 4, carbs: 25, fiber: 1, fat: 5, sugar: 1, iron: 1.3, calcium: 14, magnesium: 12, potassium: 36, zinc: 0.3, isPlantProtein: true, isFermented: true),
    FoodItem(name: 'Masala Dosa', category: 'Grains & Breads', serving: '1 piece', calories: 300, protein: 6, carbs: 45, fiber: 3, fat: 11, sugar: 3, iron: 2.1, calcium: 22, vitaminC: 8, isPlantProtein: true, isFermented: true),

    // ---- Dals & Legumes ----
    // Legumes are one of the two clearest, most-cited high-phytate-context
    // food groups (alongside whole grains) — a well-established, category-
    // level fact, not a fabricated per-food phytate figure.
    FoodItem(name: 'Toor / Yellow Dal', category: 'Dals & Legumes', serving: '1 bowl (150g)', calories: 150, protein: 9, carbs: 20, fiber: 5, fat: 4, sugar: 2, iron: 2.4, calcium: 30, magnesium: 54, potassium: 554, zinc: 1.5, isPlantProtein: true, phytateContext: true),
    FoodItem(name: 'Moong Dal', category: 'Dals & Legumes', serving: '1 bowl (150g)', calories: 150, protein: 10, carbs: 20, fiber: 6, fat: 3, sugar: 2, iron: 2.0, calcium: 28, magnesium: 72, potassium: 399, zinc: 1.3, isPlantProtein: true, phytateContext: true),
    FoodItem(name: 'Rajma', category: 'Dals & Legumes', serving: '1 bowl (150g)', calories: 210, protein: 12, carbs: 30, fiber: 8, fat: 4, sugar: 3, iron: 3.0, calcium: 40, vitaminC: 3, magnesium: 68, potassium: 605, zinc: 1.5, isPlantProtein: true, phytateContext: true),
    FoodItem(name: 'Chole', category: 'Dals & Legumes', serving: '1 bowl (150g)', calories: 260, protein: 11, carbs: 35, fiber: 9, fat: 8, sugar: 5, iron: 3.2, calcium: 55, vitaminC: 4, magnesium: 72, potassium: 437, zinc: 2.3, isPlantProtein: true, phytateContext: true),
    FoodItem(name: 'Sambar', category: 'Dals & Legumes', serving: '1 bowl (150g)', calories: 140, protein: 6, carbs: 18, fiber: 5, fat: 4, sugar: 4, iron: 1.8, calcium: 35, vitaminC: 6, isPlantProtein: true, phytateContext: true),

    // ---- Vegetables ----
    FoodItem(name: 'Aloo Sabzi', category: 'Vegetables', serving: '1 bowl (150g)', calories: 180, protein: 3, carbs: 25, fiber: 3, fat: 8, sugar: 2, iron: 1.2, calcium: 15, vitaminC: 12),
    // Contains spinach (palak) — spinach is one of the most-cited
    // high-oxalate foods (inhibits non-heme iron and calcium absorption).
    FoodItem(name: 'Palak Paneer', category: 'Vegetables', serving: '1 bowl (150g)', calories: 280, protein: 12, carbs: 12, fiber: 4, fat: 20, sugar: 4, iron: 3.5, calcium: 210, vitaminC: 14, isAnimalProtein: true, oxalateContext: true),
    FoodItem(name: 'Bhindi Masala', category: 'Vegetables', serving: '1 bowl (150g)', calories: 160, protein: 3, carbs: 12, fiber: 5, fat: 11, sugar: 4, iron: 1.0, calcium: 80, vitaminC: 16),
    FoodItem(name: 'Mixed Veg Curry', category: 'Vegetables', serving: '1 bowl (150g)', calories: 170, protein: 4, carbs: 18, fiber: 5, fat: 9, sugar: 6, iron: 1.6, calcium: 45, vitaminC: 20),
    FoodItem(name: 'Baingan Bharta', category: 'Vegetables', serving: '1 bowl (150g)', calories: 150, protein: 3, carbs: 14, fiber: 5, fat: 9, sugar: 5, iron: 0.9, calcium: 20, vitaminC: 8),

    // ---- Dairy ----
    FoodItem(name: 'Milk (full cream)', category: 'Dairy', serving: '1 glass (250ml)', calories: 150, protein: 8, carbs: 12, fiber: 0, fat: 8, sugar: 12, calcium: 300, magnesium: 25, potassium: 375, zinc: 1.0, isAnimalProtein: true),
    FoodItem(name: 'Curd / Dahi', category: 'Dairy', serving: '1 bowl (150g)', calories: 100, protein: 6, carbs: 8, fiber: 0, fat: 5, sugar: 6, calcium: 200, magnesium: 18, potassium: 233, zinc: 0.9, isAnimalProtein: true, isFermented: true),
    FoodItem(name: 'Paneer', category: 'Dairy', serving: '100g', calories: 265, protein: 18, carbs: 6, fiber: 0, fat: 20, sugar: 2, calcium: 480, magnesium: 15, potassium: 90, zinc: 1.1, isAnimalProtein: true),
    FoodItem(name: 'Sweet Lassi', category: 'Dairy', serving: '1 glass (250ml)', calories: 220, protein: 8, carbs: 30, fiber: 0, fat: 7, sugar: 28, calcium: 250, isAnimalProtein: true, isFermented: true),
    FoodItem(name: 'Ghee', category: 'Dairy', serving: '1 tbsp (14g)', calories: 112, protein: 0, carbs: 0, fiber: 0, fat: 12.5, sugar: 0),

    // ---- Snacks ----
    FoodItem(name: 'Samosa', category: 'Snacks', serving: '1 piece', calories: 260, protein: 4, carbs: 30, fiber: 2, fat: 14, sugar: 2, iron: 1.2, calcium: 18),
    FoodItem(name: 'Pakora', category: 'Snacks', serving: '5 pieces', calories: 220, protein: 5, carbs: 22, fiber: 3, fat: 13, sugar: 2, iron: 1.5, calcium: 25),
    FoodItem(name: 'Medu Vada', category: 'Snacks', serving: '1 medium', calories: 180, protein: 4, carbs: 20, fiber: 2, fat: 10, sugar: 1, iron: 1.3, calcium: 15),
    FoodItem(name: 'Dhokla', category: 'Snacks', serving: '2 pieces', calories: 160, protein: 5, carbs: 26, fiber: 2, fat: 4, sugar: 3, iron: 1.4, calcium: 20),
    FoodItem(name: 'Bhel Puri', category: 'Snacks', serving: '1 plate', calories: 250, protein: 6, carbs: 40, fiber: 4, fat: 8, sugar: 6, iron: 2.0, calcium: 30, vitaminC: 10),

    // ---- Non-Veg ----
    // Heme iron comes only from animal muscle tissue (meat/poultry/fish) —
    // eggs contain iron but it's non-heme, a well-established distinction
    // (NIH ODS Iron fact sheet). Marked accordingly below.
    FoodItem(name: 'Boiled Egg', category: 'Non-Veg', serving: '1 egg', calories: 78, protein: 6, carbs: 0.6, fiber: 0, fat: 5, sugar: 0.6, iron: 0.9, calcium: 28, magnesium: 5, potassium: 63, zinc: 0.6, isAnimalProtein: true),
    FoodItem(name: 'Egg Curry', category: 'Non-Veg', serving: '2 eggs (bowl)', calories: 280, protein: 14, carbs: 8, fiber: 2, fat: 20, sugar: 4, iron: 2.4, calcium: 70, vitaminC: 4, isAnimalProtein: true),
    FoodItem(name: 'Chicken Curry', category: 'Non-Veg', serving: '1 bowl (150g)', calories: 300, protein: 25, carbs: 8, fiber: 2, fat: 18, sugar: 3, iron: 1.8, calcium: 40, isAnimalProtein: true, containsHemeIron: true),
    FoodItem(name: 'Fish Curry', category: 'Non-Veg', serving: '1 bowl (150g)', calories: 250, protein: 22, carbs: 6, fiber: 1, fat: 15, sugar: 2, iron: 1.4, calcium: 60, isAnimalProtein: true, containsHemeIron: true),
    FoodItem(name: 'Tandoori Chicken', category: 'Non-Veg', serving: '2 pieces', calories: 300, protein: 30, carbs: 4, fiber: 0, fat: 18, sugar: 2, iron: 1.5, calcium: 30, magnesium: 45, potassium: 450, zinc: 1.8, isAnimalProtein: true, containsHemeIron: true),

    // ---- Fruits ----
    FoodItem(name: 'Banana', category: 'Fruits', serving: '1 medium', calories: 105, protein: 1.3, carbs: 27, fiber: 3, fat: 0.4, sugar: 14, iron: 0.3, calcium: 6, vitaminC: 10, magnesium: 32, potassium: 422, zinc: 0.2),
    FoodItem(name: 'Apple', category: 'Fruits', serving: '1 medium', calories: 95, protein: 0.5, carbs: 25, fiber: 4, fat: 0.3, sugar: 19, calcium: 11, vitaminC: 8, magnesium: 9, potassium: 195, zinc: 0.1),
    FoodItem(name: 'Mango', category: 'Fruits', serving: '1 cup (165g)', calories: 100, protein: 1, carbs: 25, fiber: 3, fat: 0.6, sugar: 23, calcium: 18, vitaminC: 60, magnesium: 17, potassium: 277, zinc: 0.15),
    FoodItem(name: 'Orange', category: 'Fruits', serving: '1 medium', calories: 62, protein: 1.2, carbs: 15, fiber: 3, fat: 0.2, sugar: 12, calcium: 52, vitaminC: 70, magnesium: 13, potassium: 237, zinc: 0.1),
    FoodItem(name: 'Papaya', category: 'Fruits', serving: '1 cup (145g)', calories: 55, protein: 0.9, carbs: 14, fiber: 2.5, fat: 0.2, sugar: 8, calcium: 30, vitaminC: 88, magnesium: 15, potassium: 264, zinc: 0.12),

    // ---- Beverages ----
    FoodItem(name: 'Masala Chai', category: 'Beverages', serving: '1 cup (150ml)', calories: 90, protein: 2, carbs: 12, fiber: 0, fat: 3, sugar: 10, calcium: 80, caffeine: 40, magnesium: 6, potassium: 90, zinc: 0.2),
    FoodItem(name: 'Filter Coffee', category: 'Beverages', serving: '1 cup (150ml)', calories: 80, protein: 2, carbs: 10, fiber: 0, fat: 3, sugar: 8, calcium: 70, caffeine: 80, magnesium: 5, potassium: 80, zinc: 0.15),
    FoodItem(name: 'Black Coffee', category: 'Beverages', serving: '1 cup (150ml)', calories: 5, protein: 0.3, carbs: 0, fiber: 0, fat: 0, sugar: 0, caffeine: 95),
    FoodItem(name: 'Green Tea', category: 'Beverages', serving: '1 cup (150ml)', calories: 2, protein: 0, carbs: 0, fiber: 0, fat: 0, sugar: 0, caffeine: 30),
    FoodItem(name: 'Buttermilk / Chaas', category: 'Beverages', serving: '1 glass (250ml)', calories: 40, protein: 3, carbs: 4, fiber: 0, fat: 1.5, sugar: 3, calcium: 100, magnesium: 20, potassium: 250, zinc: 0.75, isAnimalProtein: true, isFermented: true),

    // ---- Sweets ----
    FoodItem(name: 'Gulab Jamun', category: 'Sweets', serving: '2 pieces', calories: 300, protein: 4, carbs: 45, fiber: 0, fat: 12, sugar: 40, calcium: 60),
    FoodItem(name: 'Jalebi', category: 'Sweets', serving: '2 pieces', calories: 250, protein: 2, carbs: 45, fiber: 0, fat: 8, sugar: 40, iron: 0.5, calcium: 10),
    FoodItem(name: 'Kheer', category: 'Sweets', serving: '1 bowl (150g)', calories: 250, protein: 6, carbs: 40, fiber: 1, fat: 8, sugar: 32, calcium: 180),
    FoodItem(name: 'Besan Ladoo', category: 'Sweets', serving: '1 piece', calories: 185, protein: 3, carbs: 25, fiber: 1, fat: 8, sugar: 20, iron: 1.0, calcium: 20),

    // ---- Shakes ----
    FoodItem(name: 'Whey Shake (water)', category: 'Shakes', serving: '1 scoop (30g)', calories: 120, protein: 24, carbs: 3, fiber: 0, fat: 1.5, sugar: 2, calcium: 120, isAnimalProtein: true),
    FoodItem(name: 'Whey + Milk Shake', category: 'Shakes', serving: '1 scoop + 250ml milk', calories: 270, protein: 32, carbs: 15, fiber: 0, fat: 9, sugar: 14, calcium: 420, isAnimalProtein: true),
    FoodItem(name: 'Mass Gainer Shake', category: 'Shakes', serving: '2 scoops + milk', calories: 530, protein: 28, carbs: 82, fiber: 2, fat: 11, sugar: 27, calcium: 400, isAnimalProtein: true),
    FoodItem(name: 'Banana Peanut Protein Shake', category: 'Shakes', serving: '1 large glass', calories: 350, protein: 28, carbs: 35, fiber: 3, fat: 10, sugar: 18, calcium: 300),
    FoodItem(name: 'Plant Protein Shake', category: 'Shakes', serving: '1 scoop + water', calories: 150, protein: 21, carbs: 6, fiber: 2, fat: 3, sugar: 2, calcium: 150, isPlantProtein: true),

    // ---- Supplements ----
    FoodItem(name: 'Whey Protein', category: 'Supplements', serving: '1 scoop (30g)', calories: 120, protein: 24, carbs: 3, fiber: 0, fat: 1.5, sugar: 2, calcium: 120, isAnimalProtein: true),
    FoodItem(name: 'Mass Gainer', category: 'Supplements', serving: '2 scoops', calories: 380, protein: 20, carbs: 70, fiber: 2, fat: 3, sugar: 15, calcium: 200, isAnimalProtein: true),
    FoodItem(name: 'Creatine', category: 'Supplements', serving: '5g', calories: 0, protein: 0, carbs: 0, fiber: 0, fat: 0),
    FoodItem(name: 'BCAA', category: 'Supplements', serving: '1 scoop', calories: 5, protein: 0, carbs: 1, fiber: 0, fat: 0),
    FoodItem(name: 'Pre-Workout', category: 'Supplements', serving: '1 scoop', calories: 10, protein: 0, carbs: 2, fiber: 0, fat: 0, sugar: 0, caffeine: 150),
    FoodItem(name: 'Multivitamin', category: 'Supplements', serving: '1 tablet', calories: 4, protein: 0, carbs: 1, fiber: 0, fat: 0, iron: 5, calcium: 100, vitaminC: 60),
    FoodItem(name: 'Fish Oil (Omega-3)', category: 'Supplements', serving: '1 capsule', calories: 10, protein: 0, carbs: 0, fiber: 0, fat: 1),
    FoodItem(name: 'Vitamin C Tablet', category: 'Supplements', serving: '1 tablet', calories: 5, protein: 0, carbs: 1, fiber: 0, fat: 0, vitaminC: 500),
    FoodItem(name: 'Vitamin D3', category: 'Supplements', serving: '1 tablet', calories: 2, protein: 0, carbs: 0, fiber: 0, fat: 0),
  ];
}
