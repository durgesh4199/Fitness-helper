import 'strength_set.dart';

enum ProgressTrend { up, flat, down }

class ExerciseProgress {
  final String exerciseName;
  final ProgressTrend trend;
  final double latestTopEstimate;
  final double previousTopEstimate;
  final String message;

  const ExerciseProgress({
    required this.exerciseName,
    required this.trend,
    required this.latestTopEstimate,
    required this.previousTopEstimate,
    required this.message,
  });
}

/// Compares an exercise's best set from its most recent session against the
/// session before it, using estimated 1RM as the yardstick. Deliberately
/// simple (two-session comparison, not a rolling trend) and only ever
/// describes what already happened — never a target or plan.
class ProgressiveOverloadEngine {
  ProgressiveOverloadEngine._();

  static const int minSessions = 2;

  /// Below this fractional change, two sessions are treated as "about the
  /// same" rather than up/down — avoids reading noise as a trend.
  static const double flatThreshold = 0.02;

  static const String disclaimer =
      'Comparing your best estimated set this session to your last one for this exercise — a simple trend from your own logged numbers, not a training recommendation.';

  static List<ExerciseProgress> evaluate(List<StrengthSet> sets) {
    final byExercise = <String, List<StrengthSet>>{};
    for (final s in sets) {
      byExercise.putIfAbsent(s.exerciseName, () => []).add(s);
    }

    final results = <ExerciseProgress>[];
    for (final entry in byExercise.entries) {
      final withEstimate = entry.value.where((s) => s.estimated1Rm != null).toList();
      if (withEstimate.isEmpty) continue;

      final byDay = <DateTime, List<StrengthSet>>{};
      for (final s in withEstimate) {
        final day = DateTime(s.dateTime.year, s.dateTime.month, s.dateTime.day);
        byDay.putIfAbsent(day, () => []).add(s);
      }
      if (byDay.length < minSessions) continue;

      final sortedDays = byDay.keys.toList()..sort();
      final latestDay = sortedDays.last;
      final previousDay = sortedDays[sortedDays.length - 2];

      final latestTop = byDay[latestDay]!.map((s) => s.estimated1Rm!).reduce((a, b) => a > b ? a : b);
      final previousTop = byDay[previousDay]!.map((s) => s.estimated1Rm!).reduce((a, b) => a > b ? a : b);
      if (previousTop <= 0) continue;

      final change = (latestTop - previousTop) / previousTop;
      final pct = (change.abs() * 100).toStringAsFixed(0);

      ProgressTrend trend;
      String message;
      if (change > flatThreshold) {
        trend = ProgressTrend.up;
        message = 'Trending up — about $pct% higher estimated top set than last session.';
      } else if (change < -flatThreshold) {
        trend = ProgressTrend.down;
        message = 'Trending down — about $pct% lower estimated top set than last session.';
      } else {
        trend = ProgressTrend.flat;
        message = 'About the same as your last session.';
      }

      results.add(ExerciseProgress(
        exerciseName: entry.key,
        trend: trend,
        latestTopEstimate: latestTop,
        previousTopEstimate: previousTop,
        message: message,
      ));
    }

    results.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
    return results;
  }
}
