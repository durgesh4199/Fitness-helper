import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/mock_data.dart';
import '../providers/nutrition_provider.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import 'workout_session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<UserProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final recentLogs = workouts.logs.take(3).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _buildHeader(colors, user.name),
          const SizedBox(height: 24),
          _buildCalorieCard(colors, workouts, user),
          const SizedBox(height: 16),
          _buildNutritionCard(colors, nutrition),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: StatCard(
                  icon: Icons.directions_walk_rounded,
                  color: AppBrand.accentBlue,
                  value: '7,842',
                  label: 'Steps today',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.read<UserProvider>().addWater(250),
                  child: StatCard(
                    icon: Icons.water_drop_rounded,
                    color: AppBrand.accentBlue,
                    value: '${(user.waterIntakeMl / 1000).toStringAsFixed(1)} L',
                    label: 'Tap to add 250ml',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: StatCard(
                  icon: Icons.bedtime_rounded,
                  color: AppBrand.secondary,
                  value: '7h 20m',
                  label: 'Sleep',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: recentLogs.isEmpty ? 'Try a Workout' : 'Recent Workouts',
          ),
          const SizedBox(height: 14),
          if (recentLogs.isEmpty)
            ...MockData.workouts.take(3).map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutRow(
                      title: w.title,
                      subtitle: '${w.minutes} min · ${w.calories} kcal',
                      icon: w.icon,
                      color: w.color,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => WorkoutSessionScreen(template: w)),
                      ),
                    ),
                  ),
                )
          else
            ...recentLogs.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkoutRow(
                  title: l.title,
                  subtitle: '${l.minutes} min · ${l.calories} kcal',
                  icon: l.icon,
                  color: l.color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppPalette colors, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: TextStyle(fontSize: 14, color: colors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              '$name 👋',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
          ],
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.gradientStart, colors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(AppPalette colors, NutritionProvider nutrition) {
    final t = nutrition.todayTotals;
    Widget macro(String label, String value, Color color) => Column(
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.restaurant_rounded, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: macro('Eaten', '${t.calories.round()}', AppBrand.calories)),
          Expanded(child: macro('Protein', '${t.protein.round()}g', AppBrand.protein)),
          Expanded(child: macro('Carbs', '${t.carbs.round()}g', AppBrand.carbs)),
          Expanded(child: macro('Fiber', '${t.fiber.round()}g', AppBrand.fiber)),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(AppPalette colors, WorkoutProvider workouts, UserProvider user) {
    final goal = user.calorieGoal;
    final burned = workouts.todayCalories;
    final percent = goal == 0 ? 0.0 : (burned / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.gradientStart, colors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 42,
            lineWidth: 9,
            percent: percent,
            animation: true,
            animationDuration: 900,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            progressColor: Colors.white,
            center: Text(
              '${(percent * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calories burned',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$burned / $goal kcal',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${workouts.streakDays} day streak',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
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

class _WorkoutRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _WorkoutRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.play_circle_fill_rounded, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
