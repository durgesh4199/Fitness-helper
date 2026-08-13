import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/rpe_selector.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Workout template;

  const WorkoutSessionScreen({super.key, required this.template});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _finished = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() => _running = true);
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final minutes = (_elapsed.inSeconds / 60).ceil().clamp(1, 999);
    final estimatedCalories = ((widget.template.calories / widget.template.minutes) * minutes).round();

    final rpe = await _askRpe();
    if (!mounted) return;

    await context.read<WorkoutProvider>().addLog(
          WorkoutLog(
            title: widget.template.title,
            category: widget.template.category,
            minutes: minutes,
            calories: estimatedCalories,
            dateTime: DateTime.now(),
            rpe: rpe,
          ),
        );

    if (!mounted) return;
    setState(() => _finished = true);
  }

  /// Bottom sheet asking how hard the workout felt — optional, skippable.
  Future<int?> _askRpe() async {
    int? selected;
    return showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = context.colors;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nice work!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Rating effort helps build a more useful training-load trend over time.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 18),
                RpeSelector(value: selected, onChanged: (v) => setSheetState(() => selected = v)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(selected == null ? 'Skip' : 'Save', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = widget.template;

    if (_finished) {
      final minutes = (_elapsed.inSeconds / 60).ceil().clamp(1, 999);
      final estimatedCalories = ((t.calories / t.minutes) * minutes).round();
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: colors.primary, size: 44),
                ),
                const SizedBox(height: 24),
                Text(
                  'Workout logged!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '$minutes min · $estimatedCalories kcal burned',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(t.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(color: t.color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(t.icon, color: t.color, size: 42),
              ),
              const SizedBox(height: 28),
              Text(
                _format(_elapsed),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _running ? 'In progress' : (_elapsed == Duration.zero ? 'Ready to start' : 'Paused'),
                style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _toggle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(
                        _running ? 'Pause' : (_elapsed == Duration.zero ? 'Start' : 'Resume'),
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 140,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _elapsed.inSeconds > 0 ? _finish : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: const Text('Finish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
