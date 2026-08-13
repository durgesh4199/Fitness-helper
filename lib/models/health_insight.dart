import 'daily_health_log.dart';

enum InsightType { sleepStepsCorrelation }

/// A single observed pattern from the user's own history — never a
/// diagnosis, never a claim of cause and effect. Always paired with
/// [InsightEngine.disclaimer] in the UI.
class HealthInsight {
  final InsightType type;
  final String title;
  final String message;

  const HealthInsight({required this.type, required this.title, required this.message});
}

/// Finds simple, deterministic patterns in the user's own recorded history.
/// Deliberately conservative: says nothing until there's enough data, and
/// nothing when the difference found is too small to be worth mentioning.
class InsightEngine {
  InsightEngine._();

  /// Minimum number of days with *both* a steps and a sleep reading before
  /// any pattern is surfaced at all — per the spec's explicit caution
  /// against showing correlations from too little data.
  static const int minDataPoints = 14;

  /// Minimum relative difference between the two groups' averages for the
  /// pattern to be considered worth mentioning, rather than noise.
  static const double _minMeaningfulDifference = 0.10;

  static const String disclaimer = 'This is an observed pattern from your data, not proof of cause and effect.';

  /// Splits days with both a sleep and a steps reading into "more sleep"
  /// vs "less sleep" at the median, and compares their average step counts.
  /// Returns null when there isn't enough paired data yet, or when the
  /// difference between the two groups isn't meaningful.
  static HealthInsight? sleepStepsCorrelation(List<DailyHealthLog> logs) {
    final paired = logs.where((l) => l.steps != null && l.sleepMinutes != null).toList();
    if (paired.length < minDataPoints) return null;

    final sortedBySleep = [...paired]..sort((a, b) => a.sleepMinutes!.compareTo(b.sleepMinutes!));
    final medianSleep = sortedBySleep[sortedBySleep.length ~/ 2].sleepMinutes!;

    final higherSleepDays = paired.where((l) => l.sleepMinutes! > medianSleep).toList();
    final lowerSleepDays = paired.where((l) => l.sleepMinutes! <= medianSleep).toList();
    if (higherSleepDays.isEmpty || lowerSleepDays.isEmpty) return null;

    final avgHigher = higherSleepDays.map((l) => l.steps!).reduce((a, b) => a + b) / higherSleepDays.length;
    final avgLower = lowerSleepDays.map((l) => l.steps!).reduce((a, b) => a + b) / lowerSleepDays.length;
    if (avgLower <= 0) return null;

    final diffRatio = (avgHigher - avgLower).abs() / avgLower;
    if (diffRatio < _minMeaningfulDifference) return null;

    final sleepHours = (medianSleep / 60).toStringAsFixed(1);
    final direction = avgHigher > avgLower ? 'higher' : 'lower';

    return HealthInsight(
      type: InsightType.sleepStepsCorrelation,
      title: 'Sleep & activity',
      message: 'On days where your sleep is above $sleepHours hours, your average step count has been $direction.',
    );
  }

  /// All insights currently worth showing, computed from the same history.
  static List<HealthInsight> all(List<DailyHealthLog> logs) {
    return [sleepStepsCorrelation(logs)].whereType<HealthInsight>().toList();
  }
}
