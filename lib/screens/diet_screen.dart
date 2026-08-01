import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/food_log.dart';
import '../models/indian_foods.dart';
import '../models/nutrition_targets.dart';
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
            _GlucoseCard(colors: colors, nutrition: nutrition, isToday: isToday),
            const SizedBox(height: 16),
            _MicroCard(colors: colors, totals: totals, targets: targets),
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

  const _GlucoseCard({required this.colors, required this.nutrition, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final curve = nutrition.glucoseCurve;

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
                    Text('Sugar Response', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    Text('Estimated glucose after meals', style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                  ],
                ),
              ),
              if (curve.isNotEmpty) _statusChip(),
            ],
          ),
          const SizedBox(height: 16),
          if (curve.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  isToday
                      ? 'Log a meal with carbs or sugar to see\nyour estimated glucose curve.'
                      : 'No carbs or sugar logged on this day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _stat(isToday ? 'Now' : 'End of day', '${nutrition.currentGlucose.round()}', 'mg/dL', colors.primary),
                const SizedBox(width: 20),
                _stat('Peak', '${nutrition.peakGlucose.round()}', 'mg/dL', AppBrand.carbs),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 150, child: _chart(curve)),
            const SizedBox(height: 6),
            Text(
              'Estimate from logged carbs & sugar — not a medical reading.',
              style: TextStyle(fontSize: 10.5, color: colors.textSecondary.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip() {
    final status = nutrition.glucoseStatus;
    final spiking = status == 'Spiking' || status == 'Rising';
    final color = spiking ? AppBrand.accentOrange : AppBrand.fiber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _stat(String label, String value, String unit, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 3),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text('$unit  $label', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
        ),
      ],
    );
  }

  Widget _chart(List<GlucosePoint> curve) {
    final minX = curve.first.hour;
    final maxX = curve.last.hour;
    final maxLevel = curve.map((p) => p.level).reduce((a, b) => a > b ? a : b);
    final maxY = (maxLevel + 15).clamp(120.0, 260.0);

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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 30,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9.5, color: colors.textSecondary),
              ),
            ),
          ),
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
        // "In range" upper reference line at 140 mg/dL.
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 140,
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

  const _MicroBar({required this.label, required this.value, required this.goal, required this.unit, required this.color});

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
            Text('$valueStr / ${goal.round()} $unit',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: meal, actionLabel: '$mealCals kcal'),
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
                  '${_fmt(log.servings)} serving · P ${log.protein.round()}g · C ${log.carbs.round()}g · F ${log.fat.round()}g',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text('${log.calories.round()}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(width: 2),
          Text('kcal', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
        ],
      ),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
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
