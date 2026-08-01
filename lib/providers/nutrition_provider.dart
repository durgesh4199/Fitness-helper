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

/// One point on the estimated blood-glucose-response curve.
class GlucosePoint {
  final double hour; // hour of day (0-24), e.g. 13.5 = 1:30 PM
  final double level; // estimated mg/dL

  const GlucosePoint(this.hour, this.level);
}

class NutritionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  // --- Glucose model constants ---
  static const double _baseline = 90; // fasting mg/dL
  static const double _peakDelayMin = 45; // minutes to peak after eating
  static const double _rangeCeiling = 140; // "in range" upper bound

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

  /// Glycemic impact (peak mg/dL bump) a single food contributes. Sugar hits
  /// faster/harder than complex carbs; fiber blunts the response.
  double _impact(FoodLog l) {
    final complexCarbs = math.max(0.0, l.carbs - l.sugar);
    final raw = l.sugar * 1.1 + complexCarbs * 0.5;
    final fiberDamping = 1 - math.min(0.5, l.fiber * 0.025);
    return raw * fiberDamping;
  }

  /// Spike kernel: 0 at intake, rises to 1 at [_peakDelayMin], decays back.
  double _kernel(double minutesSince) {
    if (minutesSince <= 0) return 0;
    final x = minutesSince / _peakDelayMin;
    return x * math.exp(1 - x);
  }

  double _minuteOfDay(DateTime t) => t.hour * 60 + t.minute + t.second / 60;

  double _glucoseAt(double minuteOfDay, List<FoodLog> logs) {
    double level = _baseline;
    for (final l in logs) {
      level += _impact(l) * _kernel(minuteOfDay - _minuteOfDay(l.dateTime));
    }
    return level;
  }

  /// Estimated glucose curve for [date], sampled across that day's eating window.
  List<GlucosePoint> glucoseCurveForDate(DateTime date) {
    final dayLogs = logsForDate(date).where((l) => l.carbs > 0).toList();
    if (dayLogs.isEmpty) return const [];

    final firstMin = dayLogs.map((l) => _minuteOfDay(l.dateTime)).reduce(math.min);
    final lastMin = dayLogs.map((l) => _minuteOfDay(l.dateTime)).reduce(math.max);
    final start = math.max(0.0, firstMin - 30);
    final end = math.min(1440.0, lastMin + 180);

    const step = 6.0; // minutes
    final points = <GlucosePoint>[];
    for (double m = start; m <= end; m += step) {
      points.add(GlucosePoint(m / 60, _glucoseAt(m, dayLogs)));
    }
    return points;
  }

  /// The live estimate for today, or the last modeled point of a past day
  /// (there's no "now" for a day that's already over).
  double glucoseNowOrEndForDate(DateTime date) {
    final curve = glucoseCurveForDate(date);
    if (curve.isEmpty) return _baseline;
    if (_isSameDay(date, DateTime.now())) {
      final dayLogs = logsForDate(date).where((l) => l.carbs > 0).toList();
      return _glucoseAt(_minuteOfDay(DateTime.now()), dayLogs);
    }
    return curve.last.level;
  }

  double peakGlucoseForDate(DateTime date) {
    final curve = glucoseCurveForDate(date);
    if (curve.isEmpty) return _baseline;
    return curve.map((p) => p.level).reduce(math.max);
  }

  String glucoseStatusForDate(DateTime date) {
    final g = glucoseNowOrEndForDate(date);
    if (g < _baseline + 8) return 'Stable';
    if (g <= _rangeCeiling) return 'In range';
    if (g <= 160) return 'Rising';
    return 'Spiking';
  }

  // Selected-date glucose convenience getters (what the Diet screen uses).
  List<GlucosePoint> get glucoseCurve => glucoseCurveForDate(_selectedDate);
  double get currentGlucose => glucoseNowOrEndForDate(_selectedDate);
  double get peakGlucose => peakGlucoseForDate(_selectedDate);
  String get glucoseStatus => glucoseStatusForDate(_selectedDate);

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
}
