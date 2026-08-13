import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/food_log.dart';
import '../services/database_service.dart';

/// Aggregated nutrition totals for a set of food logs.
class NutritionTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fiber;
  final double fat;
  final double sugar;
  final double iron;
  final double calcium;
  final double vitaminC;
  final double caffeine;

  // Sum of only the logs that had a known value for this nutrient — see
  // the *Known flags below before treating these as the day's true total.
  final double magnesium;
  final double potassium;
  final double zinc;

  // True only if every log included in this total had a known value for
  // that nutrient. False means the sum above is a partial/lower-bound
  // figure, not the day's real total — e.g. one food's magnesium isn't in
  // the reference database yet. The UI must show this distinctly, never
  // silently present a partial sum as if it were complete.
  final bool magnesiumKnown;
  final bool potassiumKnown;
  final bool zincKnown;

  const NutritionTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.fat = 0,
    this.sugar = 0,
    this.iron = 0,
    this.calcium = 0,
    this.vitaminC = 0,
    this.caffeine = 0,
    this.magnesium = 0,
    this.potassium = 0,
    this.zinc = 0,
    this.magnesiumKnown = true,
    this.potassiumKnown = true,
    this.zincKnown = true,
  });

  NutritionTotals operator +(FoodLog l) => NutritionTotals(
        calories: calories + l.calories,
        protein: protein + l.protein,
        carbs: carbs + l.carbs,
        fiber: fiber + l.fiber,
        fat: fat + l.fat,
        sugar: sugar + l.sugar,
        iron: iron + l.iron,
        calcium: calcium + l.calcium,
        vitaminC: vitaminC + l.vitaminC,
        caffeine: caffeine + l.caffeine,
        magnesium: magnesium + (l.magnesium ?? 0),
        potassium: potassium + (l.potassium ?? 0),
        zinc: zinc + (l.zinc ?? 0),
        magnesiumKnown: magnesiumKnown && l.magnesium != null,
        potassiumKnown: potassiumKnown && l.potassium != null,
        zincKnown: zincKnown && l.zinc != null,
      );
}

class NutritionGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fiber;
  final int fat;
  final int sugar; // recommended daily limit (g)
  final int caffeineLimit; // recommended daily limit (mg)

  const NutritionGoals({
    this.calories = 2000,
    this.protein = 60,
    this.carbs = 250,
    this.fiber = 30,
    this.fat = 65,
    this.sugar = 40,
    this.caffeineLimit = 400,
  });
}

/// One point on the internal meal-impact simulation curve. This is a
/// heuristic shape, not a blood-glucose measurement — kept for drawing the
/// relative response chart, never shown to the user as an absolute reading.
class GlucosePoint {
  final double hour; // hour of day (0-24), e.g. 13.5 = 1:30 PM
  final double level; // internal simulated units, not mg/dL

  const GlucosePoint(this.hour, this.level);
}

/// Coarse, non-medical categorization of today's estimated meal impact.
/// Deliberately categorical (not a number) so the app never implies it's
/// measuring or predicting an actual blood-glucose value.
enum MealImpactLevel { veryLow, low, moderate, high, veryHigh }

extension MealImpactLevelX on MealImpactLevel {
  String get label => switch (this) {
        MealImpactLevel.veryLow => 'Very Low',
        MealImpactLevel.low => 'Low',
        MealImpactLevel.moderate => 'Moderate',
        MealImpactLevel.high => 'High',
        MealImpactLevel.veryHigh => 'Very High',
      };
}

/// A single non-medical estimate of how a day's logged meals may affect
/// glucose response, built entirely from logged carbs/sugar/fiber/portion —
/// never from an actual glucose measurement. Always pair with
/// [disclaimer] in the UI.
class MealImpactEstimate {
  final MealImpactLevel level;
  final String carbLoad; // Low | Moderate | High
  final String fiber; // Low | Moderate | High
  final String sugar; // Low | Moderate | High
  final String portionSize; // Low | Moderate | High
  final String confidence; // Low | Moderate — never "High": this is a heuristic, not a lab reading
  final bool hasData;

  const MealImpactEstimate({
    required this.level,
    required this.carbLoad,
    required this.fiber,
    required this.sugar,
    required this.portionSize,
    required this.confidence,
    this.hasData = true,
  });

  const MealImpactEstimate.empty()
      : level = MealImpactLevel.veryLow,
        carbLoad = '--',
        fiber = '--',
        sugar = '--',
        portionSize = '--',
        confidence = '--',
        hasData = false;

  static const String disclaimer =
      'This is a food-impact estimate, not a blood-glucose measurement or medical prediction.';
}

class NutritionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  // --- Glucose model constants ---
  // Diabetic constants reflect impaired insulin response: a higher baseline
  // (ADA fasting target ceiling for a controlled diabetic is ~130 mg/dL vs
  // ~90 for a non-diabetic), a slower rise to peak, a larger peak for the
  // same carbs/sugar, and a higher clinically-accepted postprandial ceiling
  // (ADA target <180 mg/dL vs the ~140 mg/dL "in range" bound used for
  // non-diabetics).
  static const double _baselineNonDiabetic = 90;
  static const double _baselineDiabetic = 126;
  static const double _peakDelayMinNonDiabetic = 45;
  static const double _peakDelayMinDiabetic = 60;
  static const double _rangeCeilingNonDiabetic = 140;
  static const double _rangeCeilingDiabetic = 180;
  static const double _diabeticSensitivity = 1.6; // larger excursion per gram of sugar/carb

  double _baselineFor(bool diabetic) => diabetic ? _baselineDiabetic : _baselineNonDiabetic;
  double _peakDelayFor(bool diabetic) => diabetic ? _peakDelayMinDiabetic : _peakDelayMinNonDiabetic;
  double _rangeCeilingFor(bool diabetic) => diabetic ? _rangeCeilingDiabetic : _rangeCeilingNonDiabetic;

  List<FoodLog> _logs = [];
  bool _loading = true;
  NutritionGoals goals = const NutritionGoals();

  /// The date currently being browsed on the Diet screen (defaults to today).
  /// Kept separate from the `today*` getters below so Home always shows the
  /// real "today" regardless of what day the user is browsing in Diet.
  DateTime _selectedDate = _dateOnly(DateTime.now());

  List<FoodLog> get logs => _logs;
  bool get loading => _loading;

  DateTime get selectedDate => _selectedDate;
  bool get isSelectedDateToday => _isSameDay(_selectedDate, DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// The earliest date with any logged food, or today if there are none yet.
  DateTime get earliestLogDate {
    if (_logs.isEmpty) return _dateOnly(DateTime.now());
    return _dateOnly(_logs.map((l) => l.dateTime).reduce((a, b) => a.isBefore(b) ? a : b));
  }

  void selectDate(DateTime date) {
    final d = _dateOnly(date);
    if (d.isAfter(_dateOnly(DateTime.now()))) return; // no browsing into the future
    _selectedDate = d;
    notifyListeners();
  }

  void shiftSelectedDate(int days) => selectDate(_selectedDate.add(Duration(days: days)));

  // ---------------------------------------------------------------------------
  // Generic date-scoped queries (used for both "today" and history browsing).
  // ---------------------------------------------------------------------------

  List<FoodLog> logsForDate(DateTime date) =>
      _logs.where((l) => _isSameDay(l.dateTime, date)).toList();

  NutritionTotals totalsForDate(DateTime date) =>
      logsForDate(date).fold(const NutritionTotals(), (t, l) => t + l);

  /// A date's logs grouped by meal, in canonical meal order.
  Map<String, List<FoodLog>> byMealForDate(DateTime date) {
    const order = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];
    final dayLogs = logsForDate(date);
    final map = <String, List<FoodLog>>{};
    for (final meal in order) {
      final items = dayLogs.where((l) => l.meal == meal).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (items.isNotEmpty) map[meal] = items;
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // "Today" convenience getters — always the real current day (used by Home).
  // ---------------------------------------------------------------------------

  List<FoodLog> get todayLogs => logsForDate(DateTime.now());
  NutritionTotals get todayTotals => totalsForDate(DateTime.now());
  Map<String, List<FoodLog>> get todayByMeal => byMealForDate(DateTime.now());

  // ---------------------------------------------------------------------------
  // Selected-date convenience getters — used by the Diet screen's history
  // browsing (defaults to today until the user navigates).
  // ---------------------------------------------------------------------------

  List<FoodLog> get selectedLogs => logsForDate(_selectedDate);
  NutritionTotals get selectedTotals => totalsForDate(_selectedDate);
  Map<String, List<FoodLog>> get selectedByMeal => byMealForDate(_selectedDate);

  // ---------------------------------------------------------------------------
  // Estimated blood-glucose response (NOT a real reading — a simple model based
  // on the carbs/sugar/fiber of what was logged and when).
  // ---------------------------------------------------------------------------

  /// Glycemic impact (peak mg/dL bump) a food's sugar/carbs/fiber contributes.
  /// Sugar hits faster/harder than complex carbs; fiber blunts the response.
  /// Diabetics see a larger excursion for the same intake due to impaired
  /// insulin response. Static and public so food-recommendation scoring can
  /// reuse the exact same model the Sugar Response chart is built from.
  static double spikeImpact({
    required double sugar,
    required double carbs,
    required double fiber,
    bool diabetic = false,
  }) {
    final complexCarbs = math.max(0.0, carbs - sugar);
    final raw = sugar * 1.1 + complexCarbs * 0.5;
    final fiberDamping = 1 - math.min(0.5, fiber * 0.025);
    final sensitivity = diabetic ? _diabeticSensitivity : 1.0;
    return raw * fiberDamping * sensitivity;
  }

  double _impact(FoodLog l, bool diabetic) =>
      spikeImpact(sugar: l.sugar, carbs: l.carbs, fiber: l.fiber, diabetic: diabetic);

  /// Spike kernel: 0 at intake, rises to 1 at [peakDelayMin], decays back.
  double _kernel(double minutesSince, double peakDelayMin) {
    if (minutesSince <= 0) return 0;
    final x = minutesSince / peakDelayMin;
    return x * math.exp(1 - x);
  }

  double _minuteOfDay(DateTime t) => t.hour * 60 + t.minute + t.second / 60;

  double _glucoseAt(double minuteOfDay, List<FoodLog> logs, bool diabetic) {
    double level = _baselineFor(diabetic);
    final peakDelay = _peakDelayFor(diabetic);
    for (final l in logs) {
      level += _impact(l, diabetic) * _kernel(minuteOfDay - _minuteOfDay(l.dateTime), peakDelay);
    }
    return level;
  }

  /// Estimated glucose curve for [date], sampled across that day's eating
  /// window. Pass [diabetic] true to model the larger, slower, longer-lasting
  /// response seen with impaired insulin sensitivity.
  List<GlucosePoint> glucoseCurveForDate(DateTime date, {bool diabetic = false}) {
    final dayLogs = logsForDate(date).where((l) => l.carbs > 0).toList();
    if (dayLogs.isEmpty) return const [];

    final firstMin = dayLogs.map((l) => _minuteOfDay(l.dateTime)).reduce(math.min);
    final lastMin = dayLogs.map((l) => _minuteOfDay(l.dateTime)).reduce(math.max);
    final start = math.max(0.0, firstMin - 30);
    final end = math.min(1440.0, lastMin + 180);

    const step = 6.0; // minutes
    final points = <GlucosePoint>[];
    for (double m = start; m <= end; m += step) {
      points.add(GlucosePoint(m / 60, _glucoseAt(m, dayLogs, diabetic)));
    }
    return points;
  }

  /// The live estimate for today, or the last modeled point of a past day
  /// (there's no "now" for a day that's already over).
  double glucoseNowOrEndForDate(DateTime date, {bool diabetic = false}) {
    final curve = glucoseCurveForDate(date, diabetic: diabetic);
    if (curve.isEmpty) return _baselineFor(diabetic);
    if (_isSameDay(date, DateTime.now())) {
      final dayLogs = logsForDate(date).where((l) => l.carbs > 0).toList();
      return _glucoseAt(_minuteOfDay(DateTime.now()), dayLogs, diabetic);
    }
    return curve.last.level;
  }

  double peakGlucoseForDate(DateTime date, {bool diabetic = false}) {
    final curve = glucoseCurveForDate(date, diabetic: diabetic);
    if (curve.isEmpty) return _baselineFor(diabetic);
    return curve.map((p) => p.level).reduce(math.max);
  }

  /// Status reflects the day's *peak*, not just the current reading — a spike
  /// that already happened and decayed back toward baseline by "now" should
  /// still be flagged, not reported as "In range".
  String glucoseStatusForDate(DateTime date, {bool diabetic = false}) {
    final g = peakGlucoseForDate(date, diabetic: diabetic);
    final baseline = _baselineFor(diabetic);
    final ceiling = _rangeCeilingFor(diabetic);
    if (g < baseline + 8) return 'Stable';
    if (g <= ceiling) return 'In range';
    if (g <= ceiling + 20) return 'Rising';
    return 'Spiking';
  }

  // Selected-date glucose convenience methods (what the Diet screen uses).
  // `diabetic` defaults to false so non-diabetic behavior is unchanged.
  List<GlucosePoint> glucoseCurve({bool diabetic = false}) =>
      glucoseCurveForDate(_selectedDate, diabetic: diabetic);
  double currentGlucose({bool diabetic = false}) =>
      glucoseNowOrEndForDate(_selectedDate, diabetic: diabetic);
  double peakGlucose({bool diabetic = false}) =>
      peakGlucoseForDate(_selectedDate, diabetic: diabetic);
  String glucoseStatus({bool diabetic = false}) =>
      glucoseStatusForDate(_selectedDate, diabetic: diabetic);

  /// Categorical, non-medical estimate of [date]'s meal impact — this is the
  /// user-facing surface of the glucose model; UI should present [level] and
  /// the breakdown fields, never [peakGlucoseForDate]'s raw number.
  MealImpactEstimate mealImpactEstimateForDate(DateTime date, {bool diabetic = false}) {
    final dayLogs = logsForDate(date).where((l) => l.carbs > 0).toList();
    if (dayLogs.isEmpty) return const MealImpactEstimate.empty();

    final totals = totalsForDate(date);
    final baseline = _baselineFor(diabetic);
    final ceiling = _rangeCeilingFor(diabetic);
    final peak = peakGlucoseForDate(date, diabetic: diabetic);

    // Normalize the peak excursion above baseline against the span to the
    // clinically-referenced "in range" ceiling, then bucket into 5 levels.
    final span = math.max(1.0, ceiling - baseline);
    final ratio = (peak - baseline) / span;

    final level = ratio <= 0.15
        ? MealImpactLevel.veryLow
        : ratio <= 0.4
            ? MealImpactLevel.low
            : ratio <= 0.85
                ? MealImpactLevel.moderate
                : ratio <= 1.15
                    ? MealImpactLevel.high
                    : MealImpactLevel.veryHigh;

    String bucket(double value, double lowMax, double moderateMax) =>
        value <= lowMax ? 'Low' : (value <= moderateMax ? 'Moderate' : 'High');

    // Confidence intentionally caps at "Moderate" — this model is a
    // heuristic, never presented as clinically confident.
    final confidence = dayLogs.length >= 3 ? 'Moderate' : 'Low';

    return MealImpactEstimate(
      level: level,
      carbLoad: bucket(totals.carbs, 40, 90),
      fiber: bucket(totals.fiber, 8, 20),
      sugar: bucket(totals.sugar, 15, 35),
      portionSize: bucket(totals.calories, 500, 1000),
      confidence: confidence,
    );
  }

  MealImpactEstimate mealImpactEstimate({bool diabetic = false}) =>
      mealImpactEstimateForDate(_selectedDate, diabetic: diabetic);

  Future<void> load() async {
    _logs = await _db.getAllFoodLogs();
    _loading = false;
    notifyListeners();
  }

  Future<void> addLog(FoodLog log) async {
    final id = await _db.insertFoodLog(log);
    _logs = [log.copyWith(id: id), ..._logs];
    notifyListeners();
  }

  Future<void> deleteLog(int id) async {
    await _db.deleteFoodLog(id);
    _logs = _logs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  /// Replaces all food logs with [logs] — used when restoring a backup.
  Future<void> restoreLogs(List<FoodLog> logs) async {
    await _db.clearAndInsertFoodLogs(logs);
    await load();
  }
}
