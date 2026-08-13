import 'workout_log.dart';

enum RecoveryLevel { considerRest, restRecommended }

class RecoverySignal {
  final RecoveryLevel level;
  final String title;
  final String message;

  const RecoverySignal({required this.level, required this.title, required this.message});

  static const String disclaimer =
      'A simple heuristic based on your recent training streak and logged effort (RPE) — not medical or coaching advice. Always listen to your body.';
}

/// Suggests a rest day might be worth considering when there's both a long
/// training streak and recent sessions have felt hard — stays silent unless
/// both signals line up, so it doesn't nag after a single tough workout.
class RecoveryAdvisor {
  RecoveryAdvisor._();

  static const int considerRestStreakDays = 4;
  static const int restRecommendedStreakDays = 6;
  static const double highEffortRpeThreshold = 7.0;

  /// Only the most recent rated sessions are considered, so a hard session
  /// weeks ago doesn't keep triggering this.
  static const int recentSessionWindow = 3;

  /// [logs] must be newest-first (as returned by the DB / WorkoutProvider).
  static RecoverySignal? evaluate(List<WorkoutLog> logs, {required int streakDays}) {
    if (streakDays < considerRestStreakDays) return null;

    final rated = logs.where((l) => l.rpe != null).take(recentSessionWindow).toList();
    if (rated.isEmpty) return null;

    final avgRpe = rated.map((l) => l.rpe!).reduce((a, b) => a + b) / rated.length;
    if (avgRpe < highEffortRpeThreshold) return null;

    final rpeLabel = avgRpe.toStringAsFixed(1);
    if (streakDays >= restRecommendedStreakDays) {
      return RecoverySignal(
        level: RecoveryLevel.restRecommended,
        title: 'Consider a rest day',
        message: '$streakDays days in a row, with recent sessions feeling tough (avg RPE $rpeLabel). '
            'A rest or light day could help recovery.',
      );
    }
    return RecoverySignal(
      level: RecoveryLevel.considerRest,
      title: 'Recovery check-in',
      message: '$streakDays days in a row of training, and recent effort has been high (avg RPE $rpeLabel). '
          'Worth watching how you feel.',
    );
  }
}
