import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/body_measurement_log.dart';
import 'package:fitness_tracker/models/daily_health_log.dart';
import 'package:fitness_tracker/models/food_item.dart';
import 'package:fitness_tracker/models/food_log.dart';
import 'package:fitness_tracker/models/strength_set.dart';
import 'package:fitness_tracker/models/water_log.dart';
import 'package:fitness_tracker/models/weight_log.dart';
import 'package:fitness_tracker/models/workout_log.dart';
import 'package:fitness_tracker/services/database_service.dart';

/// Covers the v5/v6 migration additions (weight_logs / water_logs /
/// body_measurement_logs / workout_logs.rpe) directly against the database
/// layer, including the bulk clear-and-insert methods backup restore relies
/// on.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final db = DatabaseService.instance;

  setUp(() async {
    for (final w in await db.getAllWeightLogs()) {
      if (w.id != null) await db.deleteWeightLog(w.id!);
    }
    for (final w in await db.getAllWaterLogs()) {
      if (w.id != null) await db.deleteWaterLog(w.id!);
    }
    for (final b in await db.getAllBodyMeasurementLogs()) {
      if (b.id != null) await db.deleteBodyMeasurementLog(b.id!);
    }
    for (final l in await db.getAllLogs()) {
      if (l.id != null) await db.deleteLog(l.id!);
    }
    for (final l in await db.getAllFoodLogs()) {
      if (l.id != null) await db.deleteFoodLog(l.id!);
    }
    for (final f in await db.getAllCustomFoods()) {
      if (f.id != null) await db.deleteCustomFood(f.id!);
    }
    await db.clearDailyHealthLogs();
    await db.clearAndInsertStrengthSets([]);
  });

  test('weight log insert/read round-trip, defaulting source to userEntered', () async {
    final id = await db.insertWeightLog(WeightLog(weight: 68.5, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllWeightLogs();

    expect(all.length, 1);
    expect(all.first.id, id);
    expect(all.first.weight, 68.5);
    expect(all.first.source.name, 'userEntered');
  });

  test('clearAndInsertWeightLogs replaces existing rows (backup restore path)', () async {
    await db.insertWeightLog(WeightLog(weight: 60, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertWeightLogs([
      WeightLog(weight: 70, dateTime: DateTime(2026, 2, 1)),
      WeightLog(weight: 71, dateTime: DateTime(2026, 2, 2)),
    ]);

    final all = await db.getAllWeightLogs();
    expect(all.length, 2);
    expect(all.map((w) => w.weight), containsAll(<double>[70, 71]));
  });

  test('water log insert/read round-trip', () async {
    await db.insertWaterLog(WaterLog(amountMl: 250, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllWaterLogs();
    expect(all.length, 1);
    expect(all.first.amountMl, 250);
  });

  test('clearAndInsertWaterLogs replaces existing rows (backup restore path)', () async {
    await db.insertWaterLog(WaterLog(amountMl: 100, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertWaterLogs([
      WaterLog(amountMl: 250, dateTime: DateTime(2026, 2, 1)),
      WaterLog(amountMl: 500, dateTime: DateTime(2026, 2, 2)),
    ]);

    final all = await db.getAllWaterLogs();
    expect(all.length, 2);
    expect(all.map((w) => w.amountMl), containsAll(<int>[250, 500]));
  });

  test('body measurement log insert/read round-trip (waist only)', () async {
    await db.insertBodyMeasurementLog(BodyMeasurementLog(waistCm: 84.5, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllBodyMeasurementLogs();
    expect(all.length, 1);
    expect(all.first.waistCm, 84.5);
    expect(all.first.neckCm, isNull);
  });

  test('clearAndInsertBodyMeasurementLogs replaces existing rows (backup restore path)', () async {
    await db.insertBodyMeasurementLog(BodyMeasurementLog(waistCm: 90, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertBodyMeasurementLogs([
      BodyMeasurementLog(waistCm: 85, dateTime: DateTime(2026, 2, 1)),
      BodyMeasurementLog(waistCm: 84, dateTime: DateTime(2026, 2, 2)),
    ]);

    final all = await db.getAllBodyMeasurementLogs();
    expect(all.length, 2);
    expect(all.map((b) => b.waistCm), containsAll(<double>[85, 84]));
  });

  test('workout log persists rpe alongside existing fields', () async {
    await db.insertLog(WorkoutLog(title: 'Run', category: 'Cardio', minutes: 30, calories: 250, dateTime: DateTime(2026, 1, 1), rpe: 7));

    final all = await db.getAllLogs();
    expect(all.length, 1);
    expect(all.first.rpe, 7);
    expect(all.first.trainingLoad, 210);
  });

  test('workout log without rpe still round-trips (pre-v6 shape stays valid)', () async {
    await db.insertLog(WorkoutLog(title: 'Walk', category: 'Cardio', minutes: 20, calories: 90, dateTime: DateTime(2026, 1, 1)));

    final all = await db.getAllLogs();
    expect(all.first.rpe, isNull);
  });

  test('food log persists magnesium/potassium/zinc, keeping unset ones null (not 0)', () async {
    await db.insertFoodLog(FoodLog(
      name: 'Banana',
      category: 'Fruits',
      meal: 'Snacks',
      servings: 1,
      calories: 105,
      protein: 1.3,
      carbs: 27,
      fiber: 3,
      fat: 0.4,
      sugar: 14,
      iron: 0.3,
      calcium: 6,
      vitaminC: 10,
      caffeine: 0,
      magnesium: 32,
      potassium: 422,
      zinc: null, // deliberately unknown for this row
      dateTime: DateTime(2026, 1, 1),
    ));

    final all = await db.getAllFoodLogs();
    expect(all.length, 1);
    expect(all.first.magnesium, 32);
    expect(all.first.potassium, 422);
    expect(all.first.zinc, isNull);
  });

  test('food log with no micronutrient data at all round-trips as null, not 0 (pre-v7 shape)', () async {
    await db.insertFoodLog(FoodLog(
      name: 'Samosa',
      category: 'Snacks',
      meal: 'Snacks',
      servings: 1,
      calories: 260,
      protein: 4,
      carbs: 30,
      fiber: 2,
      fat: 14,
      sugar: 2,
      iron: 1.2,
      calcium: 18,
      vitaminC: 0,
      caffeine: 0,
      dateTime: DateTime(2026, 1, 1),
    ));

    final all = await db.getAllFoodLogs();
    expect(all.first.magnesium, isNull);
    expect(all.first.potassium, isNull);
    expect(all.first.zinc, isNull);
  });

  test('custom food carries magnesium/potassium/zinc through upsert', () async {
    await db.upsertCustomFood(const FoodItem(
      name: 'My Trail Mix',
      category: 'Snacks',
      serving: '1 handful (30g)',
      calories: 150,
      protein: 5,
      carbs: 12,
      fiber: 2,
      fat: 9,
      magnesium: 40,
      potassium: 200,
      zinc: 1.1,
    ));

    final all = await db.getAllCustomFoods();
    expect(all.length, 1);
    expect(all.first.magnesium, 40);
    expect(all.first.potassium, 200);
    expect(all.first.zinc, 1.1);
  });

  test('food log persists bioavailability context flags, keeping unset ones null (not false)', () async {
    await db.insertFoodLog(FoodLog(
      name: 'Chicken Curry',
      category: 'Non-Veg',
      meal: 'Dinner',
      servings: 1,
      calories: 300,
      protein: 25,
      carbs: 8,
      fiber: 2,
      fat: 18,
      sugar: 3,
      iron: 1.8,
      calcium: 40,
      vitaminC: 0,
      caffeine: 0,
      containsHemeIron: true,
      isAnimalProtein: true,
      // phytateContext/oxalateContext/isPlantProtein/isFermented deliberately left unset.
      dateTime: DateTime(2026, 1, 1),
    ));

    final all = await db.getAllFoodLogs();
    expect(all.length, 1);
    expect(all.first.containsHemeIron, isTrue);
    expect(all.first.isAnimalProtein, isTrue);
    expect(all.first.phytateContext, isNull);
    expect(all.first.oxalateContext, isNull);
    expect(all.first.isPlantProtein, isNull);
    expect(all.first.isFermented, isNull);
  });

  test('custom food carries bioavailability context flags through upsert', () async {
    await db.upsertCustomFood(const FoodItem(
      name: 'Homemade Dal',
      category: 'Dals & Legumes',
      serving: '1 bowl',
      calories: 150,
      protein: 9,
      carbs: 20,
      fiber: 5,
      fat: 4,
      isPlantProtein: true,
      phytateContext: true,
    ));

    final all = await db.getAllCustomFoods();
    expect(all.length, 1);
    expect(all.first.isPlantProtein, isTrue);
    expect(all.first.phytateContext, isTrue);
    expect(all.first.containsHemeIron, isNull);
    expect(all.first.oxalateContext, isNull);
  });

  test('daily health log insert/read round-trip', () async {
    await db.upsertDailyHealthLog(DailyHealthLog(date: DateTime(2026, 1, 1), steps: 8000, sleepMinutes: 420));

    final all = await db.getAllDailyHealthLogs();
    expect(all.length, 1);
    expect(all.first.steps, 8000);
    expect(all.first.sleepMinutes, 420);
    expect(all.first.dateKey, '2026-01-01');
  });

  test('upsertDailyHealthLog replaces (not duplicates) the row for the same day', () async {
    await db.upsertDailyHealthLog(DailyHealthLog(date: DateTime(2026, 1, 1), steps: 5000, sleepMinutes: 300));
    await db.upsertDailyHealthLog(DailyHealthLog(date: DateTime(2026, 1, 1), steps: 9000, sleepMinutes: 480));

    final all = await db.getAllDailyHealthLogs();
    expect(all.length, 1);
    expect(all.first.steps, 9000);
    expect(all.first.sleepMinutes, 480);
  });

  test('different days get separate rows', () async {
    await db.upsertDailyHealthLog(DailyHealthLog(date: DateTime(2026, 1, 1), steps: 5000));
    await db.upsertDailyHealthLog(DailyHealthLog(date: DateTime(2026, 1, 2), steps: 6000));

    final all = await db.getAllDailyHealthLogs();
    expect(all.length, 2);
  });

  test('strength set insert/read round-trip, including a null (bodyweight) weight', () async {
    await db.insertStrengthSet(StrengthSet(
      workoutLogId: 1,
      exerciseName: 'Pull-up',
      setIndex: 1,
      reps: 12,
      weightKg: null,
      dateTime: DateTime(2026, 1, 1),
    ));

    final all = await db.getAllStrengthSets();
    expect(all.length, 1);
    expect(all.first.exerciseName, 'Pull-up');
    expect(all.first.reps, 12);
    expect(all.first.weightKg, isNull);
  });

  test('getStrengthSetsForWorkout only returns sets for that workout, ordered by set index', () async {
    await db.insertStrengthSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 2, reps: 5, weightKg: 90, dateTime: DateTime(2026, 1, 1)));
    await db.insertStrengthSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 80, dateTime: DateTime(2026, 1, 1)));
    await db.insertStrengthSet(StrengthSet(workoutLogId: 2, exerciseName: 'Bench Press', setIndex: 1, reps: 8, weightKg: 50, dateTime: DateTime(2026, 1, 1)));

    final workout1Sets = await db.getStrengthSetsForWorkout(1);
    expect(workout1Sets.length, 2);
    expect(workout1Sets.map((s) => s.setIndex).toList(), [1, 2]);
  });

  test('deleteStrengthSetsForWorkout removes only that workout\'s sets', () async {
    await db.insertStrengthSet(StrengthSet(workoutLogId: 1, exerciseName: 'Squat', setIndex: 1, reps: 5, weightKg: 80, dateTime: DateTime(2026, 1, 1)));
    await db.insertStrengthSet(StrengthSet(workoutLogId: 2, exerciseName: 'Bench Press', setIndex: 1, reps: 8, weightKg: 50, dateTime: DateTime(2026, 1, 1)));

    await db.deleteStrengthSetsForWorkout(1);

    final all = await db.getAllStrengthSets();
    expect(all.length, 1);
    expect(all.first.workoutLogId, 2);
  });

  test('clearAndInsertStrengthSets replaces existing rows (backup restore path)', () async {
    await db.insertStrengthSet(StrengthSet(workoutLogId: 1, exerciseName: 'Old', setIndex: 1, reps: 5, weightKg: 40, dateTime: DateTime(2026, 1, 1)));

    await db.clearAndInsertStrengthSets([
      StrengthSet(workoutLogId: 5, exerciseName: 'Deadlift', setIndex: 1, reps: 5, weightKg: 100, dateTime: DateTime(2026, 2, 1)),
    ]);

    final all = await db.getAllStrengthSets();
    expect(all.length, 1);
    expect(all.first.exerciseName, 'Deadlift');
  });
}
