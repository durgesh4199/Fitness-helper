import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
import '../models/indian_foods.dart';
import '../providers/food_catalog_provider.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';
import 'manage_food_list_screen.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final catalog = context.watch<FoodCatalogProvider>();
    final foods = catalog.allItems.where((f) {
      final matchesCat = _category == 'All' || f.category == _category;
      final matchesQuery = _query.isEmpty || f.name.toLowerCase().contains(_query.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Add food'),
        actions: [
          IconButton(
            tooltip: 'Manage food list',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageFoodListScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search foods…',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CatChip(label: 'All', selected: _category == 'All', onTap: () => setState(() => _category = 'All')),
                  ...catalog.categories.map((c) => _CatChip(
                        label: c.name,
                        color: c.color,
                        selected: _category == c.name,
                        onTap: () => setState(() => _category = c.name),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: foods.isEmpty
                  ? Center(child: Text('No foods found', style: TextStyle(color: colors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: foods.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _FoodRow(
                        food: foods[i],
                        onTap: () => _openLogSheet(context, foods[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLogSheet(BuildContext context, FoodItem food) {
    final navigator = Navigator.of(context);
    showLogFoodSheet(context, food).then((saved) {
      if (saved == true && mounted) navigator.pop();
    });
  }
}

/// Opens the servings/meal picker sheet to log [food], resolving to `true` if
/// the user saved it. Shared with call sites outside [AddFoodScreen] (e.g.
/// food recommendation cards) so they use the exact same log-food UI.
Future<bool?> showLogFoodSheet(BuildContext context, FoodItem food) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LogFoodSheet(food: food),
  );
}

class _CatChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({required this.label, this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = color ?? colors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c : colors.cardBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const _FoodRow({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = IndianFoods.colorFor(food.category);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(IndianFoods.iconFor(food.category), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            food.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                          ),
                        ),
                        if (food.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Custom', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: colors.primary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(food.serving, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${food.calories.round()} kcal', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Icon(Icons.add_circle_rounded, color: colors.primary, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogFoodSheet extends StatefulWidget {
  final FoodItem food;
  const LogFoodSheet({super.key, required this.food});

  @override
  State<LogFoodSheet> createState() => _LogFoodSheetState();
}

class _LogFoodSheetState extends State<LogFoodSheet> {
  double _servings = 1;
  late String _meal = _defaultMeal();

  static const _meals = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  String _defaultMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Breakfast';
    if (h < 16) return 'Lunch';
    if (h < 19) return 'Snacks';
    return 'Dinner';
  }

  Future<void> _save() async {
    final log = FoodLog.fromItem(widget.food, _servings, _meal, DateTime.now());
    await context.read<NutritionProvider>().addLog(log);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final f = widget.food;
    final color = IndianFoods.colorFor(f.category);

    double v(double base) => base * _servings;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(IndianFoods.iconFor(f.category), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(f.serving, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Servings stepper.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Servings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                Row(
                  children: [
                    _StepButton(icon: Icons.remove_rounded, onTap: () => setState(() => _servings = (_servings - 0.5).clamp(0.5, 20))),
                    Container(
                      width: 56,
                      alignment: Alignment.center,
                      child: Text(_fmt(_servings), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    ),
                    _StepButton(icon: Icons.add_rounded, onTap: () => setState(() => _servings = (_servings + 0.5).clamp(0.5, 20))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Meal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: _meals.map((m) {
                final selected = _meal == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _meal = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? colors.primary : colors.cardBorder),
                      ),
                      child: Text(
                        m,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            // Live nutrition preview.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Macro(label: 'Cals', value: '${v(f.calories).round()}', color: AppBrand.calories),
                  _Macro(label: 'Protein', value: '${v(f.protein).round()}g', color: AppBrand.protein),
                  _Macro(label: 'Carbs', value: '${v(f.carbs).round()}g', color: AppBrand.carbs),
                  _Macro(label: 'Fat', value: '${v(f.fat).round()}g', color: AppBrand.fat),
                  _Macro(label: 'Fiber', value: '${v(f.fiber).round()}g', color: AppBrand.fiber),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Add to diary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: colors.primary, size: 20),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Macro({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }
}
