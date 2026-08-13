import '../models/nutrition_targets.dart';
import '../providers/nutrition_provider.dart';

/// One input to the Daily Wellness Score — kept separate from the
/// activity/nutrition data sources it draws from so the score's own logic
/// stays pure and unit-testable.
enum WellnessComponent { nutrition, activity, hydration, sleep, consistency }

extension WellnessComponentX on WellnessComponent {
  String get label => switch (this) {
        WellnessComponent.nutrition => 'Nutrition',
        WellnessComponent.activity => 'Activity',
        WellnessComponent.hydration => 'Hydration',
        WellnessComponent.sleep => 'Sleep',
        WellnessComponent.consistency => 'Consistency',
      };
}

class WellnessComponentScore {
  final WellnessComponent component;
  final int score; // 0-100

  const WellnessComponentScore(this.component, this.score);
}

/// A transparent, non-medical "how's today going" summary — never called a
/// health score or risk score. Deterministic: the same inputs always
/// produce the same output, and every component's formula is documented
/// below rather than hidden behind a model.
class DailyWellnessScore {
  final int score; // 0-100, average of the components that had real data
  final String label; // Great | Good | Fair | Needs attention
  final List<WellnessComponentScore> components;

  const DailyWellnessScore({required this.score, required this.label, required this.components});

  static const empty = DailyWellnessScore(score: 0, label: 'No data yet', components: []);
}

class DailyWellnessCalculator {
  DailyWellnessCalculator._();

  // A sleep duration inside this window scores 100; scores fall off by 20
  // points per hour of distance outside it, floored at 0. This is a
  // general wellness heuristic (roughly the commonly cited 7-9h adult
  // range), not an individualized or medical sleep recommendation.
  static const int _sleepIdealMinLow = 420; // 7h
  static const int _sleepIdealMinHigh = 540; // 9h

  // A flat, modest reference used only when no personalized step goal is
  // available (e.g. watch not connected) — 30 active minutes is a commonly
  // cited general activity guideline, not a personalized target.
  static const double _fallbackActivityMinutes = 30;

  // Workouts/week used as the consistency reference — a moderate, broadly
  // reasonable cadence, not a personalized or clinical target.
  static const double _consistencyTargetPerWeek = 4;

  static int _percentOf(double actual, double target) {
    if (target <= 0) return 0;
    return ((actual / target).clamp(0.0, 1.0) * 100).round();
  }

  static DailyWellnessScore compute({
    required NutritionTotals totals,
    required NutritionTargets targets,
    required int waterIntakeMl,
    required int waterGoalMl,
    int? steps,
    int? stepGoal,
    int? sleepMinutes,
    required int todayWorkoutMinutes,
    required int weekWorkoutCount,
  }) {
    final components = <WellnessComponentScore>[];

    // Nutrition: average of protein-goal%, fiber-goal%, and how close
    // today's calories are to target (symmetric — over or under both pull
    // the score down, since the goal is hitting the target, not just a
    // floor).
    final proteinPct = _percentOf(totals.protein, targets.protein.toDouble());
    final fiberPct = _percentOf(totals.fiber, targets.fiber.toDouble());
    final calorieCloseness = targets.calories <= 0
        ? 0
        : (100 - (((totals.calories - targets.calories).abs() / targets.calories) * 100).clamp(0.0, 100.0)).round();
    components.add(WellnessComponentScore(
      WellnessComponent.nutrition,
      ((proteinPct + fiberPct + calorieCloseness) / 3).round(),
    ));

    // Activity: percent of the personalized step goal when we have one
    // (from Health Connect), otherwise today's workout minutes against a
    // flat general-activity reference.
    final activityScore = (steps != null && stepGoal != null && stepGoal > 0)
        ? _percentOf(steps.toDouble(), stepGoal.toDouble())
        : _percentOf(todayWorkoutMinutes.toDouble(), _fallbackActivityMinutes);
    components.add(WellnessComponentScore(WellnessComponent.activity, activityScore));

    // Hydration: percent of the user's water goal reached today.
    components.add(WellnessComponentScore(
      WellnessComponent.hydration,
      _percentOf(waterIntakeMl.toDouble(), waterGoalMl.toDouble()),
    ));

    // Sleep: only scored when we actually have a reading — never invented.
    if (sleepMinutes != null) {
      int sleepScore;
      if (sleepMinutes >= _sleepIdealMinLow && sleepMinutes <= _sleepIdealMinHigh) {
        sleepScore = 100;
      } else {
        final distanceMin =
            sleepMinutes < _sleepIdealMinLow ? _sleepIdealMinLow - sleepMinutes : sleepMinutes - _sleepIdealMinHigh;
        sleepScore = (100 - (distanceMin / 60 * 20)).clamp(0, 100).round();
      }
      components.add(WellnessComponentScore(WellnessComponent.sleep, sleepScore));
    }

    // Consistency: this week's workout count against a moderate reference.
    components.add(WellnessComponentScore(
      WellnessComponent.consistency,
      _percentOf(weekWorkoutCount.toDouble(), _consistencyTargetPerWeek),
    ));

    if (components.isEmpty) return DailyWellnessScore.empty;

    final avg = (components.map((c) => c.score).reduce((a, b) => a + b) / components.length).round();
    final label = avg >= 80
        ? 'Great'
        : avg >= 65
            ? 'Good'
            : avg >= 50
                ? 'Fair'
                : 'Needs attention';

    return DailyWellnessScore(score: avg, label: label, components: components);
  }

  /// Up to 4 concrete, prioritized suggestions derived from today's actual
  /// remaining gaps — worst gap first. Returns fewer (or none) when there's
  /// simply not much left to close; never invents a suggestion when the
  /// underlying data isn't available (e.g. no sleep reading).
  static List<String> focusSuggestions({
    required NutritionTotals totals,
    required NutritionTargets targets,
    required int waterIntakeMl,
    required int waterGoalMl,
    int? steps,
    int? stepGoal,
    int? sleepMinutes,
  }) {
    final gaps = <(String, double)>[];

    void addIfShort(String text, double actual, double target, {double threshold = 0.3}) {
      if (target <= 0) return;
      final deficit = 1 - (actual / target).clamp(0.0, 1.0);
      if (deficit >= threshold) gaps.add((text, deficit));
    }

    addIfShort('Increase protein', totals.protein, targets.protein.toDouble());
    addIfShort('Add fiber', totals.fiber, targets.fiber.toDouble());
    addIfShort('Drink water', waterIntakeMl.toDouble(), waterGoalMl.toDouble());
    if (steps != null && stepGoal != null) {
      addIfShort('Take a short walk', steps.toDouble(), stepGoal.toDouble());
    }
    if (sleepMinutes != null && sleepMinutes < _sleepIdealMinLow) {
      gaps.add(('Prioritize sleep tonight', (_sleepIdealMinLow - sleepMinutes) / _sleepIdealMinLow));
    }

    gaps.sort((a, b) => b.$2.compareTo(a.$2));
    return gaps.take(4).map((g) => g.$1).toList();
  }
}
