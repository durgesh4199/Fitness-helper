import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mock_data.dart';
import '../models/recovery_signal.dart';
import '../models/strength_progress.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../providers/strength_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import 'add_workout_screen.dart';
import 'log_sets_screen.dart';
import 'workout_session_screen.dart';

String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(date.year, date.month, date.day);
  if (d == today) return 'Today';
  if (d == yesterday) return 'Yesterday';
  return DateFormat('EEEE, MMM d').format(date);
}

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _selectedCategory == 'All'
        ? MockData.workouts
        : MockData.workouts.where((w) => w.category == _selectedCategory).toList();
    final workoutProvider = context.watch<WorkoutProvider>();
    final logs = workoutProvider.logs;
    final recovery = workoutProvider.recoverySignal;
    final progress = context.watch<StrengthProvider>().progress;

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddWorkoutScreen()),
        ),
        backgroundColor: colors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Log workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(
              'Workouts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a category and get moving',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            if (recovery != null) ...[
              const SizedBox(height: 18),
              _RecoveryCard(signal: recovery, colors: colors),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = MockData.categories[index];
                  final selected = _selectedCategory == cat.name;
                  return _CategoryChip(
                    category: cat,
                    selected: selected,
                    onTap: () => setState(() {
                      _selectedCategory = selected ? 'All' : cat.name;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: _selectedCategory == 'All' ? 'All Workouts' : _selectedCategory,
            ),
            const SizedBox(height: 14),
            ...filtered.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TemplateTile(
                  workout: w,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkoutSessionScreen(template: w)),
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No workouts in this category yet.', style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            if (progress.isNotEmpty) ...[
              const SizedBox(height: 28),
              const SectionHeader(title: 'Exercise Progress'),
              const SizedBox(height: 14),
              ...progress.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProgressTile(progress: p, colors: colors),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  ProgressiveOverloadEngine.disclaimer,
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colors.textSecondary),
                ),
              ),
            ],
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 28),
              const SectionHeader(title: 'History'),
              const SizedBox(height: 14),
              ..._buildGroupedHistory(colors, logs),
            ],
          ],
        ),
      ),
    );
  }

  /// [logs] arrives sorted newest-first from the DB, so a single linear pass
  /// grouping consecutive same-day entries is enough — no re-sorting needed.
  List<Widget> _buildGroupedHistory(AppPalette colors, List<WorkoutLog> logs) {
    final widgets = <Widget>[];
    DateTime? lastDay;

    for (final log in logs) {
      final day = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      if (lastDay == null || day != lastDay) {
        if (lastDay != null) widgets.add(const SizedBox(height: 18));
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _dayLabel(log.dateTime),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
            ),
          ),
        );
        lastDay = day;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey(log.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              context.read<WorkoutProvider>().deleteLog(log.id!);
              context.read<StrengthProvider>().deleteSetsForWorkout(log.id!);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            child: _HistoryTile(log: log, colors: colors),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _HistoryTile extends StatelessWidget {
  final WorkoutLog log;
  final AppPalette colors;

  const _HistoryTile({required this.log, required this.colors});

  bool get _isStrength => log.category == 'Strength';

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: log.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(log.icon, color: log.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${log.minutes} min · ${log.calories} kcal${log.rpe != null ? ' · RPE ${log.rpe}' : ''}',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(log.dateTime),
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          if (_isStrength) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
          ],
        ],
      ),
    );

    if (!_isStrength || log.id == null) return content;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LogSetsScreen(workoutLogId: log.id!, workoutTitle: log.title)),
      ),
      child: content,
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _TemplateTile({required this.workout, required this.onTap});

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
                decoration: BoxDecoration(
                  color: workout.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(workout.icon, color: workout.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${workout.minutes} min', style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                        const SizedBox(width: 10),
                        Icon(Icons.local_fire_department_rounded, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${workout.calories} kcal', style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: workout.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: workout.color, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final WorkoutCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? category.color : colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: selected ? category.color.withValues(alpha: 0.35) : colors.shadow,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: selected ? Colors.white : category.color, size: 26),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final RecoverySignal signal;
  final AppPalette colors;

  const _RecoveryCard({required this.signal, required this.colors});

  @override
  Widget build(BuildContext context) {
    final strong = signal.level == RecoveryLevel.restRecommended;
    final accent = strong ? Colors.deepOrange : colors.secondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.self_improvement_rounded, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.title, style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text(signal.message, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  RecoverySignal.disclaimer,
                  style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final ExerciseProgress progress;
  final AppPalette colors;

  const _ProgressTile({required this.progress, required this.colors});

  IconData get _icon {
    switch (progress.trend) {
      case ProgressTrend.up:
        return Icons.trending_up_rounded;
      case ProgressTrend.down:
        return Icons.trending_down_rounded;
      case ProgressTrend.flat:
        return Icons.trending_flat_rounded;
    }
  }

  Color get _color {
    switch (progress.trend) {
      case ProgressTrend.up:
        return Colors.green;
      case ProgressTrend.down:
        return Colors.redAccent;
      case ProgressTrend.flat:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progress.exerciseName, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(progress.message, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
