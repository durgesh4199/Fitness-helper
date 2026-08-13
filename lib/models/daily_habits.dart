import 'food_log.dart';

/// Today's habit checklist — every item is derived from data the app
/// already tracks (no separate manual "did you do this?" entry to keep in
/// sync), computed fresh each day. Consistency is about noticing patterns
/// over time, not a perfection streak to chase.
class DailyHabits {
  final bool waterGoalMet;
  final bool workoutDone;
  final bool walked; // met (or made meaningful progress toward) the step goal
  final bool ateVegOrFruit;
  final bool? sleepTargetMet; // null when there's no sleep reading yet today

  const DailyHabits({
    required this.waterGoalMet,
    required this.workoutDone,
    required this.walked,
    required this.ateVegOrFruit,
    required this.sleepTargetMet,
  });

  /// How many of the *known* habits were met today (sleep excluded from
  /// both counts when there's no reading, rather than counted as unmet).
  int get metCount => [waterGoalMet, workoutDone, walked, ateVegOrFruit, ?sleepTargetMet]
      .where((v) => v)
      .length;

  int get totalCount => 4 + (sleepTargetMet != null ? 1 : 0);

  static const _vegFruitCategories = {'vegetables', 'fruits'};
  static const int _sleepTargetMinMinutes = 420; // 7h, general reference — see DailyWellnessCalculator

  static DailyHabits compute({
    required int waterIntakeMl,
    required int waterGoalMl,
    required int todayWorkoutMinutes,
    required List<FoodLog> todayLogs,
    int? steps,
    int? stepGoal,
    int? sleepMinutes,
  }) {
    final walked = (steps != null && stepGoal != null && stepGoal > 0) ? steps >= stepGoal : todayWorkoutMinutes > 0;

    return DailyHabits(
      waterGoalMet: waterGoalMl > 0 && waterIntakeMl >= waterGoalMl,
      workoutDone: todayWorkoutMinutes > 0,
      walked: walked,
      ateVegOrFruit: todayLogs.any((l) => _vegFruitCategories.contains(l.category.toLowerCase())),
      sleepTargetMet: sleepMinutes == null ? null : sleepMinutes >= _sleepTargetMinMinutes,
    );
  }
}
