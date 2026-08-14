import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
import '../models/food_recommendation.dart';
import '../models/indian_foods.dart';
import '../models/meal_quality.dart';
import '../models/nutrition_targets.dart';
import '../providers/food_catalog_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import 'add_food_screen.dart';

const int _caffeineLimitMg = 400;

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nutrition = context.watch<NutritionProvider>();
    final user = context.watch<UserProvider>();
    final catalog = context.watch<FoodCatalogProvider>();
    final totals = nutrition.selectedTotals;
    final targets = NutritionTargets.forUser(user);
    final byMeal = nutrition.selectedByMeal;
    final isToday = nutrition.isSelectedDateToday;

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          nutrition.selectDate(DateTime.now());
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFoodScreen()));
        },
        backgroundColor: colors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add food', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text('Diet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 4),
            if (isToday)
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 13, color: colors.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Targets personalized for you · ${targets.goalLabel}',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ],
              )
            else
              Text('Viewing a past day', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            const SizedBox(height: 16),
            _DateNavigator(colors: colors, nutrition: nutrition),
            const SizedBox(height: 20),
            _CalorieCard(colors: colors, consumed: totals.calories.round(), goal: targets.calories),
            const SizedBox(height: 16),
            _MacroCard(colors: colors, totals: totals, targets: targets),
            const SizedBox(height: 16),
            _SugarCaffeineCard(colors: colors, totals: totals, targets: targets),
            const SizedBox(height: 16),
            _GlucoseCard(colors: colors, nutrition: nutrition, isToday: isToday, isDiabetic: user.isDiabetic),
            const SizedBox(height: 16),
            _MicroCard(colors: colors, totals: totals, targets: targets),
            if (isToday) ...[
              const SizedBox(height: 16),
              _RecommendationsCard(
                colors: colors,
                totals: totals,
                targets: targets,
                catalog: catalog.allItems,
                diabetic: user.isDiabetic,
                consumedToday: nutrition.selectedLogs,
              ),
            ],
            const SizedBox(height: 26),
            if (byMeal.isEmpty)
              _EmptyState(colors: colors, isToday: isToday)
            else
              ...byMeal.entries.map((e) => _MealSection(meal: e.key, logs: e.value)),
          ],
        ),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final AppPalette colors;
  final NutritionProvider nutrition;

  const _DateNavigator({required this.colors, required this.nutrition});

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final date = nutrition.selectedDate;
    final canGoForward = !nutrition.isSelectedDateToday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            colors: colors,
            onTap: () => nutrition.shiftSelectedDate(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                _label(date),
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            colors: colors,
            onTap: canGoForward ? () => nutrition.shiftSelectedDate(1) : null,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final AppPalette colors;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Icon(icon, color: enabled ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.3), size: 22),
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  final AppPalette colors;
  final int consumed;
  final int goal;

  const _CalorieCard({required this.colors, required this.consumed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal - consumed);
    final percent = goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.gradientStart, colors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 44,
            lineWidth: 9,
            percent: percent,
            animation: true,
            animationDuration: 800,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            progressColor: Colors.white,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$consumed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const Text('kcal', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calories eaten', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$consumed / $goal', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    remaining >= 0 ? '$remaining kcal left' : '${-remaining} kcal over',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final AppPalette colors;
  final NutritionTotals totals;
  final NutritionTargets targets;

  const _MacroCard({required this.colors, required this.totals, required this.targets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _MacroBar(label: 'Protein', value: totals.protein, goal: targets.protein, color: AppBrand.protein),
          const SizedBox(height: 14),
          _MacroBar(label: 'Carbs', value: totals.carbs, goal: targets.carbs, color: AppBrand.carbs),
          const SizedBox(height: 14),
          _MacroBar(label: 'Fat', value: totals.fat, goal: targets.fat, color: AppBrand.fat),
          const SizedBox(height: 14),
          _MacroBar(label: 'Fiber', value: totals.fiber, goal: targets.fiber, color: AppBrand.fiber),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final int goal;
  final Color color;

  const _MacroBar({required this.label, required this.value, required this.goal, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = goal == 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
            Text('${value.round()} / $goal g', style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _SugarCaffeineCard extends StatelessWidget {
  final AppPalette colors;
  final NutritionTotals totals;
  final NutritionTargets targets;

  const _SugarCaffeineCard({required this.colors, required this.totals, required this.targets});

  @override
  Widget build(BuildContext context) {
    final sugarPct = targets.sugar == 0 ? 0.0 : (totals.sugar / targets.sugar).clamp(0.0, 1.0);
    final caffPct = _caffeineLimitMg == 0 ? 0.0 : (totals.caffeine / _caffeineLimitMg).clamp(0.0, 1.0);
    final sugarOver = totals.sugar > targets.sugar;
    final caffOver = totals.caffeine > _caffeineLimitMg;

    Widget tile({
      required IconData icon,
      required Color color,
      required String label,
      required String value,
      required String limit,
      required double pct,
      required bool over,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  if (over)
                    Icon(Icons.warning_amber_rounded, color: AppBrand.accentOrange, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(over ? AppBrand.accentOrange : color),
                ),
              ),
              const SizedBox(height: 6),
              Text(limit, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(
          icon: Icons.cake_rounded,
          color: AppBrand.carbs,
          label: 'Sugar',
          value: '${totals.sugar.round()} g',
          limit: 'of ${targets.sugar} g limit',
          pct: sugarPct,
          over: sugarOver,
        ),
        const SizedBox(width: 14),
        tile(
          icon: Icons.coffee_rounded,
          color: AppBrand.accentOrange,
          label: 'Caffeine',
          value: '${totals.caffeine.round()} mg',
          limit: 'of $_caffeineLimitMg mg limit',
          pct: caffPct,
          over: caffOver,
        ),
      ],
    );
  }
}

class _GlucoseCard extends StatelessWidget {
  final AppPalette colors;
  final NutritionProvider nutrition;
  final bool isToday;
  final bool isDiabetic;

  const _GlucoseCard({
    required this.colors,
    required this.nutrition,
    required this.isToday,
    required this.isDiabetic,
  });

  @override
  Widget build(BuildContext context) {
    final curve = nutrition.glucoseCurve(diabetic: isDiabetic);
    final estimate = nutrition.mealImpactEstimate(diabetic: isDiabetic);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.show_chart_rounded, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meal Impact Estimate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    Text('How today\'s meals may affect glucose response', style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                  ],
                ),
              ),
              if (estimate.hasData) _levelChip(estimate.level),
            ],
          ),
          const SizedBox(height: 16),
          if (!estimate.hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  isToday
                      ? 'Log a meal with carbs or sugar to see\nyour estimated meal impact.'
                      : 'No carbs or sugar logged on this day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _breakdownStat('Carb load', estimate.carbLoad, colors),
                _breakdownStat('Fiber', estimate.fiber, colors),
                _breakdownStat('Sugar', estimate.sugar, colors),
                _breakdownStat('Portion', estimate.portionSize, colors),
              ],
            ),
            const SizedBox(height: 10),
            Text('Confidence: ${estimate.confidence}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.textSecondary)),
            if (curve.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(height: 120, child: _chart(curve)),
            ],
            const SizedBox(height: 10),
            Text(
              MealImpactEstimate.disclaimer,
              style: TextStyle(fontSize: 10.5, color: colors.textSecondary.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(MealImpactLevel level) {
    final elevated = level == MealImpactLevel.high || level == MealImpactLevel.veryHigh;
    final color = elevated ? AppBrand.accentOrange : AppBrand.fiber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(level.label.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _breakdownStat(String label, String value, AppPalette colors) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _chart(List<GlucosePoint> curve) {
    final minX = curve.first.hour;
    final maxX = curve.last.hour;
    final maxLevel = curve.map((p) => p.level).reduce((a, b) => a > b ? a : b);
    // Floor of 120 keeps small ranges readable; no upper cap so a real spike
    // is never clipped off the top of the chart.
    final maxY = (maxLevel + 15).clamp(120.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 70,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (v) => FlLine(color: colors.textSecondary.withValues(alpha: 0.12), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          // No numeric y-axis — this chart shows the *shape* of the estimated
          // response over the day, not an absolute value that could be
          // mistaken for a real glucose reading.
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: ((maxX - minX) / 3).clamp(1, 24),
              getTitlesWidget: (v, meta) {
                final h = v.round() % 24;
                final ampm = h < 12 ? 'am' : 'pm';
                final display = h % 12 == 0 ? 12 : h % 12;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('$display$ampm', style: TextStyle(fontSize: 9.5, color: colors.textSecondary)),
                );
              },
            ),
          ),
        ),
        // "In range" upper reference line — 140 mg/dL for non-diabetics,
        // the ADA postprandial target of 180 mg/dL for diabetics.
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: isDiabetic ? 180 : 140,
            color: AppBrand.accentOrange.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ]),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final p in curve) FlSpot(p.hour, p.level)],
            isCurved: true,
            barWidth: 3,
            color: colors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.primary.withValues(alpha: 0.3), colors.primary.withValues(alpha: 0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroCard extends StatelessWidget {
  final AppPalette colors;
  final NutritionTotals totals;
  final NutritionTargets targets;

  const _MicroCard({required this.colors, required this.totals, required this.targets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vitamins & Minerals',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 16),
          _MicroBar(label: 'Iron', value: totals.iron, goal: targets.iron.toDouble(), unit: 'mg', color: AppBrand.accentPink),
          const SizedBox(height: 14),
          _MicroBar(label: 'Calcium', value: totals.calcium, goal: targets.calcium.toDouble(), unit: 'mg', color: AppBrand.accentBlue),
          const SizedBox(height: 14),
          _MicroBar(label: 'Vitamin C', value: totals.vitaminC, goal: targets.vitaminC.toDouble(), unit: 'mg', color: AppBrand.accentOrange),
          const SizedBox(height: 18),
          Text('More minerals',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(
            'Only shown for foods with a known value — logged foods without one aren\'t counted as zero.',
            style: TextStyle(fontSize: 10.5, color: colors.textSecondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          _MicroBar(
            label: 'Magnesium',
            value: totals.magnesium,
            goal: targets.magnesium.toDouble(),
            unit: 'mg',
            color: AppBrand.secondary,
            known: totals.magnesiumKnown,
          ),
          const SizedBox(height: 14),
          _MicroBar(
            label: 'Potassium',
            value: totals.potassium,
            goal: targets.potassium.toDouble(),
            unit: 'mg',
            color: AppBrand.primary,
            known: totals.potassiumKnown,
          ),
          const SizedBox(height: 14),
          _MicroBar(
            label: 'Zinc',
            value: totals.zinc,
            goal: targets.zinc.toDouble(),
            unit: 'mg',
            color: AppBrand.accentPink,
            known: totals.zincKnown,
          ),
        ],
      ),
    );
  }
}

class _MicroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  /// False when at least one logged food today didn't have a known value
  /// for this nutrient — [value] is then a partial/lower-bound sum, not
  /// the real total, so it's shown as such rather than as a percentage.
  final bool known;

  const _MicroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    this.known = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = goal == 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    final valueStr = value < 10 ? value.toStringAsFixed(1) : value.round().toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
            if (known)
              Text('$valueStr / ${goal.round()} $unit',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w600))
            else if (value > 0)
              Text('≥$valueStr $unit · limited data',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary, fontStyle: FontStyle.italic))
            else
              Text('No data logged',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary, fontStyle: FontStyle.italic)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: known ? pct : 0,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: known ? 0.15 : 0.08),
            valueColor: AlwaysStoppedAnimation(known ? color : Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _RecoSection {
  final RecommendedNutrient nutrient;
  final double remaining;
  final List<FoodRecommendation> picks;
  const _RecoSection(this.nutrient, this.remaining, this.picks);
}

class _RecommendationsCard extends StatefulWidget {
  final AppPalette colors;
  final NutritionTotals totals;
  final NutritionTargets targets;
  final List<FoodItem> catalog;
  final bool diabetic;
  final List<FoodLog> consumedToday;

  const _RecommendationsCard({
    required this.colors,
    required this.totals,
    required this.targets,
    required this.catalog,
    required this.diabetic,
    required this.consumedToday,
  });

  static Color _colorFor(RecommendedNutrient n) => switch (n) {
        RecommendedNutrient.protein => AppBrand.protein,
        RecommendedNutrient.fiber => AppBrand.fiber,
        RecommendedNutrient.iron => AppBrand.accentPink,
        RecommendedNutrient.calcium => AppBrand.accentBlue,
      };

  static IconData _iconFor(RecommendedNutrient n) => switch (n) {
        RecommendedNutrient.protein => Icons.fitness_center_rounded,
        RecommendedNutrient.fiber => Icons.eco_rounded,
        RecommendedNutrient.iron => Icons.bloodtype_rounded,
        RecommendedNutrient.calcium => Icons.spa_rounded,
      };

  @override
  State<_RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends State<_RecommendationsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final totals = widget.totals;
    final targets = widget.targets;
    final remainingCalories = math.max(0.0, targets.calories - totals.calories);

    List<FoodRecommendation> picksFor(RecommendedNutrient nutrient, double remaining) =>
        FoodRecommendationEngine.recommendFor(
          nutrient: nutrient,
          remainingAmount: remaining,
          remainingCalories: remainingCalories,
          catalog: widget.catalog,
          diabetic: widget.diabetic,
        );

    // Only surface a nutrient once there's a meaningful amount of today's
    // target left (>=15%) — avoids nagging once you're basically done.
    _RecoSection? section(RecommendedNutrient nutrient, double achieved, double target) {
      final remaining = math.max(0.0, target - achieved);
      if (target <= 0 || remaining / target < 0.15) return null;
      final picks = picksFor(nutrient, remaining);
      if (picks.isEmpty) return null;
      return _RecoSection(nutrient, remaining, picks);
    }

    final sections = [
      section(RecommendedNutrient.protein, totals.protein, targets.protein.toDouble()),
      section(RecommendedNutrient.fiber, totals.fiber, targets.fiber.toDouble()),
      section(RecommendedNutrient.iron, totals.iron, targets.iron.toDouble()),
      section(RecommendedNutrient.calcium, totals.calcium, targets.calcium.toDouble()),
    ].whereType<_RecoSection>().toList();

    final remainingMap = <RecommendedNutrient, double>{
      RecommendedNutrient.protein: math.max(0.0, targets.protein - totals.protein),
      RecommendedNutrient.fiber: math.max(0.0, targets.fiber - totals.fiber),
      RecommendedNutrient.iron: math.max(0.0, targets.iron - totals.iron),
      RecommendedNutrient.calcium: math.max(0.0, targets.calcium - totals.calcium),
    };
    final combos = FoodRecommendationEngine.recommendCombinations(
      remaining: remainingMap,
      remainingCalories: remainingCalories,
      catalog: widget.catalog,
      diabetic: widget.diabetic,
    );

    if (sections.isEmpty && combos.isEmpty) return const SizedBox.shrink();

    final tipCount = sections.fold<int>(0, (s, sec) => s + sec.picks.length) + combos.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(Icons.recommend_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Finish Your Targets',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                ),
                if (!_expanded)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text('$tipCount ideas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.primary)),
                  ),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: colors.textSecondary),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            Text(
              widget.diabetic
                  ? 'Won\'t spike your sugar, and skips the oily stuff.'
                  : 'Picks to close today\'s gaps without the oily stuff.',
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            _ConsumedTodayView(logs: widget.consumedToday),
            if (combos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ComboSectionView(combos: combos),
            ],
            for (final s in sections) ...[
              const SizedBox(height: 16),
              _RecoSectionView(section: s, color: _RecommendationsCard._colorFor(s.nutrient), icon: _RecommendationsCard._iconFor(s.nutrient)),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConsumedTodayView extends StatelessWidget {
  final List<FoodLog> logs;

  const _ConsumedTodayView({required this.logs});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sorted = [...logs]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consumed today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text('Nothing logged yet today.', style: TextStyle(fontSize: 12.5, color: colors.textSecondary))
        else
          ...sorted.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: colors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(log.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(log.meal, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    const SizedBox(width: 8),
                    Text('${log.calories.round()} kcal',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                  ],
                ),
              )),
      ],
    );
  }
}

class _RecoSectionView extends StatelessWidget {
  final _RecoSection section;
  final Color color;
  final IconData icon;

  const _RecoSectionView({required this.section, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final n = section.nutrient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text('Boost your ${n.label.toLowerCase()}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const Spacer(),
            Text('${section.remaining.round()}${n.unit} left',
                style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ...section.picks.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecoTile(rec: p, nutrient: n, color: color),
            )),
      ],
    );
  }
}

class _RecoTile extends StatelessWidget {
  final FoodRecommendation rec;
  final RecommendedNutrient nutrient;
  final Color color;

  const _RecoTile({required this.rec, required this.nutrient, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final f = rec.item;
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showLogFoodSheet(context, f),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(f.serving, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${rec.amount.round()}${nutrient.unit}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 2),
                  Text('${(rec.fillPercent * 100).round()}% of goal',
                      style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_rounded, color: colors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComboSectionView extends StatelessWidget {
  final List<FoodComboRecommendation> combos;

  const _ComboSectionView({required this.combos});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.ramen_dining_rounded, size: 15, color: colors.primary),
            const SizedBox(width: 6),
            Text('Suggested meals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        ...combos.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ComboTile(combo: c),
            )),
      ],
    );
  }
}

class _ComboTile extends StatelessWidget {
  final FoodComboRecommendation combo;

  const _ComboTile({required this.combo});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${combo.first.name} + ${combo.second.name}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
              ),
              Text('${combo.combinedCalories.round()} kcal', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: combo.combinedAmounts.entries
                .where((e) => e.value > 0)
                .map((e) => Text(
                      '${e.key.label} +${e.value.round()}${e.key.unit}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _RecommendationsCard._colorFor(e.key)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _ComboLogButton(food: combo.first)),
              const SizedBox(width: 8),
              Expanded(child: _ComboLogButton(food: combo.second)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComboLogButton extends StatelessWidget {
  final FoodItem food;

  const _ComboLogButton({required this.food});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton.icon(
      onPressed: () => showLogFoodSheet(context, food),
      icon: const Icon(Icons.add_rounded, size: 15),
      label: Text(food.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String meal;
  final List<FoodLog> logs;

  const _MealSection({required this.meal, required this.logs});

  @override
  Widget build(BuildContext context) {
    final mealCals = logs.fold<double>(0, (s, l) => s + l.calories).round();
    final quality = MealQualityScorer.score(logs);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: meal, actionLabel: '$mealCals kcal'),
          const SizedBox(height: 8),
          _MealQualityRow(quality: quality),
          const SizedBox(height: 12),
          ...logs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(log.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => context.read<NutritionProvider>().deleteLog(log.id!),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  child: _FoodLogTile(log: log),
                ),
              )),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Compact "Meal quality" readout: a score chip that expands into the
/// underlying checklist. Neutral labels only — never "good"/"bad" food
/// judgments, just which factors this meal met.
class _MealQualityRow extends StatefulWidget {
  final MealQualityResult quality;

  const _MealQualityRow({required this.quality});

  @override
  State<_MealQualityRow> createState() => _MealQualityRowState();
}

class _MealQualityRowState extends State<_MealQualityRow> {
  bool _expanded = false;

  Color _scoreColor(AppPalette colors, int score) {
    if (score >= 80) return AppBrand.fiber;
    if (score >= 50) return AppBrand.accentOrange;
    return colors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final q = widget.quality;
    final color = _scoreColor(colors, q.score);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Text('Meal quality ${q.score}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
              ),
              const SizedBox(width: 6),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16, color: colors.textSecondary),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: q.checks.entries
                  .map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            e.value ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            size: 13,
                            color: e.value ? AppBrand.fiber : AppBrand.accentOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(e.key.label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;

  const _FoodLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = IndianFoods.colorFor(log.category);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(IndianFoods.iconFor(log.category), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(log.servings)} serving',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MacroChip(label: 'Protein', grams: log.protein, color: AppBrand.protein),
                    _MacroChip(label: 'Carbs', grams: log.carbs, color: AppBrand.carbs),
                    _MacroChip(label: 'Fat', grams: log.fat, color: AppBrand.fat),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${log.calories.round()}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              Text('kcal', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// A small labeled, colored pill for one macronutrient — e.g. "Protein 20g".
/// Used instead of a single-letter abbreviation (the old "P 20g") so it's
/// readable at a glance without having to remember what P/C/F stand for.
class _MacroChip extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const _MacroChip({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            '$label ${grams.round()}g',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppPalette colors;
  final bool isToday;
  const _EmptyState({required this.colors, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.restaurant_rounded, color: colors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            isToday ? 'No meals logged yet' : 'No meals logged on this day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? 'Tap “Add food” to log your first Indian meal\nand watch your nutrition add up.'
                : 'Nothing was recorded for this date.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
