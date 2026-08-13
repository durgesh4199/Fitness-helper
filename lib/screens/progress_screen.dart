import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final workouts = context.watch<WorkoutProvider>();
    final user = context.watch<UserProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            workouts.weekOffset == 0 ? 'Your activity for this week' : 'Browsing a past week',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          _WeekNavigator(colors: colors, workouts: workouts),
          const SizedBox(height: 20),
          _buildChartCard(colors, workouts),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.emoji_events_rounded,
                  color: AppBrand.accentOrange,
                  value: '${workouts.weekWorkoutCount}',
                  label: 'Workouts done',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  icon: Icons.local_fire_department_rounded,
                  color: AppBrand.primary,
                  value: '${workouts.weekCalories}',
                  label: 'Kcal burned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.schedule_rounded,
                  color: AppBrand.secondary,
                  value: '${workouts.weekMinutes} min',
                  label: 'Active time',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  icon: Icons.local_fire_department_outlined,
                  color: AppBrand.accentBlue,
                  value: '${workouts.streakDays}',
                  label: 'Day streak',
                ),
              ),
            ],
          ),
          if (workouts.weekTrainingLoad != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.speed_rounded,
                    color: AppBrand.accentPink,
                    value: '${workouts.weekTrainingLoad}',
                    label: 'Training load (min × RPE)',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          const SectionHeader(title: 'Body Weight'),
          const SizedBox(height: 14),
          _buildWeightCard(colors, user),
        ],
      ),
    );
  }

  Widget _buildChartCard(AppPalette colors, WorkoutProvider workouts) {
    final data = workouts.weeklyActivity;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            maxY: 1.15,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        data[index].label,
                        style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(data.length, (index) {
              final isMax = data[index].value == 1.0;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data[index].value == 0 ? 0.02 : data[index].value,
                    width: 20,
                    borderRadius: BorderRadius.circular(8),
                    color: isMax ? colors.primary : colors.primary.withValues(alpha: 0.25),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightCard(AppPalette colors, UserProvider user) {
    final diff = user.weightKg - user.goalWeightKg;
    final losing = diff > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current weight',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.weightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      losing ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${diff.abs().toStringAsFixed(1)} kg to goal (${user.goalWeightKg.toStringAsFixed(0)} kg)',
                      style: TextStyle(fontSize: 12.5, color: colors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.monitor_weight_rounded, color: colors.primary, size: 28),
          ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final AppPalette colors;
  final WorkoutProvider workouts;

  const _WeekNavigator({required this.colors, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final start = workouts.weekStartDate;
    final end = workouts.weekEndDate;
    final sameMonth = start.month == end.month;
    final label = sameMonth
        ? '${DateFormat('MMM d').format(start)} - ${DateFormat('d').format(end)}'
        : '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    final canGoForward = workouts.weekOffset < 0;

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
          _WeekNavButton(
            icon: Icons.chevron_left_rounded,
            colors: colors,
            onTap: () => workouts.shiftWeek(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                workouts.weekOffset == 0 ? 'This week · $label' : label,
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
            ),
          ),
          _WeekNavButton(
            icon: Icons.chevron_right_rounded,
            colors: colors,
            onTap: canGoForward ? () => workouts.shiftWeek(1) : null,
          ),
        ],
      ),
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  final IconData icon;
  final AppPalette colors;
  final VoidCallback? onTap;

  const _WeekNavButton({required this.icon, required this.colors, required this.onTap});

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
