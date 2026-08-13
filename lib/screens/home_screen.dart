import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/mock_data.dart';
import '../models/water_log.dart';
import '../providers/health_provider.dart';
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
    final health = context.watch<HealthProvider>();
    final recentLogs = workouts.logs.take(3).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _buildHeader(colors, user.name),
          const SizedBox(height: 24),
          _buildCalorieCard(colors, workouts, user, health),
          const SizedBox(height: 16),
          _buildNutritionCard(colors, nutrition),
          const SizedBox(height: 24),
          if (health.status != HealthConnectionStatus.authorized)
            _buildConnectWatchCard(colors, health)
          else
            _buildSyncStatusRow(colors, health),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.directions_walk_rounded,
                  color: AppBrand.accentBlue,
                  value: health.steps?.toString() ?? '--',
                  label: (health.steps != null && health.stepGoal != null)
                      ? '${((health.steps! / health.stepGoal!) * 100).clamp(0, 999).round()}% of ${health.stepGoal} goal'
                      : 'Steps today',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  icon: Icons.favorite_rounded,
                  color: AppBrand.accentPink,
                  value: health.heartRate != null ? '${health.heartRate!.round()} bpm' : '--',
                  label: 'Heart rate',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showWaterSheet(context),
                  child: StatCard(
                    icon: Icons.water_drop_rounded,
                    color: AppBrand.accentBlue,
                    value: '${(user.waterIntakeMl / 1000).toStringAsFixed(1)} L',
                    label: 'Tap to log water',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  icon: Icons.bedtime_rounded,
                  color: AppBrand.secondary,
                  value: health.sleepLabel,
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
                  subtitle: '${l.minutes} min · ${l.calories} kcal${l.rpe != null ? ' · RPE ${l.rpe}' : ''}',
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

  Widget _buildConnectWatchCard(AppPalette colors, HealthProvider health) {
    final notInstalled = health.status == HealthConnectionStatus.notInstalled;
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
            child: Icon(Icons.watch_rounded, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connect your watch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  notInstalled
                      ? 'Install Health Connect to bring in steps, heart rate & sleep from Zepp.'
                      : 'Pull steps, heart rate & sleep synced from Zepp (Amazfit) via Health Connect.',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => health.connect(),
            style: TextButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(notInstalled ? 'Install' : 'Connect', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusRow(AppPalette colors, HealthProvider health) {
    String label;
    if (health.isSyncing) {
      label = 'Syncing with your watch…';
    } else if (health.lastSynced != null) {
      final mins = DateTime.now().difference(health.lastSynced!).inMinutes;
      label = mins < 1 ? 'Synced just now' : 'Synced ${mins}m ago';
    } else {
      label = 'Not synced yet';
    }

    return Row(
      children: [
        Icon(Icons.watch_rounded, size: 14, color: colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        GestureDetector(
          onTap: health.isSyncing ? null : () => health.syncNow(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (health.isSyncing)
                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
              else
                Icon(Icons.refresh_rounded, size: 14, color: colors.primary),
              const SizedBox(width: 4),
              Text('Sync now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
            ],
          ),
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

  Widget _buildCalorieCard(AppPalette colors, WorkoutProvider workouts, UserProvider user, HealthProvider health) {
    final goal = user.calorieGoal;
    final fromWatch = health.status == HealthConnectionStatus.authorized && health.caloriesBurned != null;
    final burned = fromWatch ? health.caloriesBurned!.round() : workouts.todayCalories;
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
                Text(
                  fromWatch ? 'Calories burned · from your watch' : 'Calories burned',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
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

void _showWaterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WaterQuickAddSheet(),
  );
}

class _WaterQuickAddSheet extends StatefulWidget {
  const _WaterQuickAddSheet();

  @override
  State<_WaterQuickAddSheet> createState() => _WaterQuickAddSheetState();
}

class _WaterQuickAddSheetState extends State<_WaterQuickAddSheet> {
  final _customController = TextEditingController();
  List<WaterLog>? _logs;

  @override
  void initState() {
    super.initState();
    context.read<UserProvider>().allWaterLogs().then((logs) {
      if (mounted) setState(() => _logs = logs);
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Average daily total over the last 7 days that have any entry — days
  /// with nothing logged aren't counted as zero, since that would just
  /// reflect missing data rather than actually drinking nothing.
  double? get _weeklyAverageMl {
    final logs = _logs;
    if (logs == null || logs.isEmpty) return null;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final byDay = <String, int>{};
    for (final l in logs) {
      if (l.dateTime.isBefore(cutoff)) continue;
      final key = '${l.dateTime.year}-${l.dateTime.month}-${l.dateTime.day}';
      byDay[key] = (byDay[key] ?? 0) + l.amountMl;
    }
    if (byDay.isEmpty) return null;
    return byDay.values.reduce((a, b) => a + b) / byDay.length;
  }

  Future<void> _add(int ml) async {
    await context.read<UserProvider>().addWater(ml);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<UserProvider>();
    final avg = _weeklyAverageMl;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log water', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            avg == null
                ? 'Today: ${(user.waterIntakeMl / 1000).toStringAsFixed(1)} L'
                : 'Today: ${(user.waterIntakeMl / 1000).toStringAsFixed(1)} L · 7-day avg: ${(avg / 1000).toStringAsFixed(1)} L',
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final ml in [100, 250, 500]) ...[
                Expanded(child: _amountButton(colors, ml)),
                if (ml != 500) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Custom amount (ml)',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  final ml = int.tryParse(_customController.text.trim());
                  if (ml != null && ml > 0) _add(ml);
                },
                style: TextButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountButton(AppPalette colors, int ml) {
    return OutlinedButton(
      onPressed: () => _add(ml),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text('+$ml ml', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
