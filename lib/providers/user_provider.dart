import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_log.dart';
import '../services/database_service.dart';

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

extension ActivityLevelX on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Light',
        ActivityLevel.moderate => 'Moderate',
        ActivityLevel.active => 'Active',
        ActivityLevel.veryActive => 'Very active',
      };

  String get hint => switch (this) {
        ActivityLevel.sedentary => 'Little/no exercise',
        ActivityLevel.light => '1–3 days/week',
        ActivityLevel.moderate => '3–5 days/week',
        ActivityLevel.active => '6–7 days/week',
        ActivityLevel.veryActive => 'Hard daily / physical job',
      };

  /// TDEE multiplier applied to BMR.
  double get factor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };

  /// Protein grams per kg of bodyweight recommended at this activity level.
  double get proteinPerKg => switch (this) {
        ActivityLevel.sedentary => 1.0,
        ActivityLevel.light => 1.2,
        ActivityLevel.moderate => 1.4,
        ActivityLevel.active => 1.6,
        ActivityLevel.veryActive => 1.8,
      };
}

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  static const _kOnboardingComplete = 'onboarding_complete';
  static const _kName = 'user_name';
  static const _kHeight = 'user_height_cm';
  static const _kWeight = 'user_weight_kg';
  static const _kGoalWeight = 'user_goal_weight_kg';
  static const _kAge = 'user_age';
  static const _kSex = 'user_sex';
  static const _kActivity = 'user_activity';
  static const _kCalorieGoal = 'user_calorie_goal';
  static const _kWaterGoal = 'user_water_goal_ml';
  static const _kWaterIntake = 'water_intake_ml';
  static const _kWaterDate = 'water_intake_date';
  static const _kIsDiabetic = 'user_is_diabetic';

  bool _loading = true;
  bool _onboardingComplete = false;
  String _name = 'Durgesh';
  double _heightCm = 172;
  double _weightKg = 68.4;
  double _goalWeightKg = 65;
  int _age = 25;
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  int _calorieGoal = 800;
  int _waterGoalMl = 2500;
  int _waterIntakeMl = 0;
  bool _isDiabetic = false;

  bool get loading => _loading;
  bool get onboardingComplete => _onboardingComplete;
  String get name => _name;
  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  double get goalWeightKg => _goalWeightKg;
  int get age => _age;
  Sex get sex => _sex;
  ActivityLevel get activity => _activity;
  int get calorieGoal => _calorieGoal;
  int get waterGoalMl => _waterGoalMl;
  int get waterIntakeMl => _waterIntakeMl;
  bool get isDiabetic => _isDiabetic;

  double get bmi {
    final heightM = _heightCm / 100;
    if (heightM <= 0) return 0;
    return _weightKg / (heightM * heightM);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool(_kOnboardingComplete) ?? false;
    _name = prefs.getString(_kName) ?? _name;
    _heightCm = prefs.getDouble(_kHeight) ?? _heightCm;
    _weightKg = prefs.getDouble(_kWeight) ?? _weightKg;
    _goalWeightKg = prefs.getDouble(_kGoalWeight) ?? _goalWeightKg;
    _age = prefs.getInt(_kAge) ?? _age;
    _sex = (prefs.getString(_kSex) == 'female') ? Sex.female : Sex.male;
    _activity = ActivityLevel.values.firstWhere(
      (a) => a.name == prefs.getString(_kActivity),
      orElse: () => ActivityLevel.moderate,
    );
    _calorieGoal = prefs.getInt(_kCalorieGoal) ?? _calorieGoal;
    _waterGoalMl = prefs.getInt(_kWaterGoal) ?? _waterGoalMl;
    _isDiabetic = prefs.getBool(_kIsDiabetic) ?? _isDiabetic;

    final storedDate = prefs.getString(_kWaterDate);
    _waterIntakeMl = storedDate == _todayKey ? (prefs.getInt(_kWaterIntake) ?? 0) : 0;

    _loading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required int age,
    required Sex sex,
    required ActivityLevel activity,
  }) async {
    _name = name;
    _heightCm = heightCm;
    _weightKg = weightKg;
    _goalWeightKg = goalWeightKg;
    _age = age;
    _sex = sex;
    _activity = activity;
    _onboardingComplete = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingComplete, true);
    await prefs.setString(_kName, name);
    await prefs.setDouble(_kHeight, heightCm);
    await prefs.setDouble(_kWeight, weightKg);
    await prefs.setDouble(_kGoalWeight, goalWeightKg);
    await prefs.setInt(_kAge, age);
    await prefs.setString(_kSex, sex.name);
    await prefs.setString(_kActivity, activity.name);
  }

  Future<void> updateProfile({
    String? name,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    int? age,
    Sex? sex,
    ActivityLevel? activity,
    int? calorieGoal,
    int? waterGoalMl,
    bool? isDiabetic,
  }) async {
    _name = name ?? _name;
    _heightCm = heightCm ?? _heightCm;
    _weightKg = weightKg ?? _weightKg;
    _goalWeightKg = goalWeightKg ?? _goalWeightKg;
    _age = age ?? _age;
    _sex = sex ?? _sex;
    _activity = activity ?? _activity;
    _calorieGoal = calorieGoal ?? _calorieGoal;
    _waterGoalMl = waterGoalMl ?? _waterGoalMl;
    _isDiabetic = isDiabetic ?? _isDiabetic;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _name);
    await prefs.setDouble(_kHeight, _heightCm);
    await prefs.setDouble(_kWeight, _weightKg);
    await prefs.setDouble(_kGoalWeight, _goalWeightKg);
    await prefs.setInt(_kAge, _age);
    await prefs.setString(_kSex, _sex.name);
    await prefs.setString(_kActivity, _activity.name);
    await prefs.setInt(_kCalorieGoal, _calorieGoal);
    await prefs.setInt(_kWaterGoal, _waterGoalMl);
    await prefs.setBool(_kIsDiabetic, _isDiabetic);
  }

  Future<void> addWater(int ml) async {
    _waterIntakeMl = (_waterIntakeMl + ml).clamp(0, 20000);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWaterIntake, _waterIntakeMl);
    await prefs.setString(_kWaterDate, _todayKey);

    // Also keep a permanent log entry so history/weekly-average features can
    // be built later without changing the fast "today" counter above.
    await _db.insertWaterLog(WaterLog(amountMl: ml, dateTime: DateTime.now()));
  }

  /// All water-log entries ever recorded, newest first — used for history
  /// views and backup export. The day-to-day quick total stays on
  /// [waterIntakeMl]/[addWater] above.
  Future<List<WaterLog>> allWaterLogs() => _db.getAllWaterLogs();

  /// Replaces all water logs with [logs] — used when restoring a backup.
  Future<void> restoreWaterLogs(List<WaterLog> logs) => _db.clearAndInsertWaterLogs(logs);

  /// Profile fields worth carrying across a backup. Excludes today's water
  /// intake, which is transient day-to-day state, not a durable setting.
  Map<String, Object?> toBackupMap() => {
        'name': _name,
        'heightCm': _heightCm,
        'weightKg': _weightKg,
        'goalWeightKg': _goalWeightKg,
        'age': _age,
        'sex': _sex.name,
        'activity': _activity.name,
        'calorieGoal': _calorieGoal,
        'waterGoalMl': _waterGoalMl,
        'isDiabetic': _isDiabetic,
      };

  /// Restores profile fields from a backup snapshot (see [toBackupMap]).
  Future<void> restoreProfile(Map<String, Object?> data) async {
    await updateProfile(
      name: data['name'] as String?,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      goalWeightKg: (data['goalWeightKg'] as num?)?.toDouble(),
      age: (data['age'] as num?)?.toInt(),
      sex: Sex.values.firstWhere((s) => s.name == data['sex'], orElse: () => _sex),
      activity: ActivityLevel.values.firstWhere((a) => a.name == data['activity'], orElse: () => _activity),
      calorieGoal: (data['calorieGoal'] as num?)?.toInt(),
      waterGoalMl: (data['waterGoalMl'] as num?)?.toInt(),
      isDiabetic: data['isDiabetic'] as bool?,
    );

    if (!_onboardingComplete) {
      _onboardingComplete = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingComplete, true);
      notifyListeners();
    }
  }
}
