/// A single logged set (exercise, reps, weight) within a strength workout.
/// Several of these can belong to one [WorkoutLog] — that log keeps the
/// overall duration/calories, this table adds the set-by-set detail needed
/// for progressive-overload tracking.
class StrengthSet {
  final int? id;
  final int workoutLogId;
  final String exerciseName;

  /// 1-based order this set was logged in within its workout.
  final int setIndex;
  final int reps;

  /// Null for bodyweight-only sets (no added weight).
  final double? weightKg;
  final DateTime dateTime;

  const StrengthSet({
    this.id,
    required this.workoutLogId,
    required this.exerciseName,
    required this.setIndex,
    required this.reps,
    this.weightKg,
    required this.dateTime,
  });

  /// Rough estimated one-rep max (Epley formula) — useful only as a relative
  /// number for comparing sessions over time, not a weight to actually
  /// attempt. Null when there's no weight recorded (bodyweight set) since a
  /// 1RM estimate is meaningless without a load.
  double? get estimated1Rm {
    final w = weightKg;
    if (w == null || w <= 0 || reps <= 0) return null;
    if (reps == 1) return w;
    return w * (1 + reps / 30.0);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_name': exerciseName,
      'set_index': setIndex,
      'reps': reps,
      'weight_kg': weightKg,
      'date_time': dateTime.toIso8601String(),
    };
  }

  factory StrengthSet.fromMap(Map<String, Object?> map) {
    return StrengthSet(
      id: map['id'] as int?,
      workoutLogId: map['workout_log_id'] as int,
      exerciseName: map['exercise_name'] as String,
      setIndex: map['set_index'] as int,
      reps: map['reps'] as int,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      dateTime: DateTime.parse(map['date_time'] as String),
    );
  }

  StrengthSet copyWith({int? id}) {
    return StrengthSet(
      id: id ?? this.id,
      workoutLogId: workoutLogId,
      exerciseName: exerciseName,
      setIndex: setIndex,
      reps: reps,
      weightKg: weightKg,
      dateTime: dateTime,
    );
  }
}
