import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_tracker/models/workout_log.dart';
import 'package:fitness_tracker/providers/body_measurement_provider.dart';
import 'package:fitness_tracker/providers/food_catalog_provider.dart';
import 'package:fitness_tracker/providers/nutrition_provider.dart';
import 'package:fitness_tracker/providers/strength_provider.dart';
import 'package:fitness_tracker/providers/user_provider.dart';
import 'package:fitness_tracker/providers/weight_provider.dart';
import 'package:fitness_tracker/providers/workout_provider.dart';
import 'package:fitness_tracker/services/cloud_backup_service.dart';

const _uid = 'test-uid';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late UserProvider user;
  late WorkoutProvider workouts;
  late NutritionProvider nutrition;
  late FoodCatalogProvider catalog;
  late WeightProvider weight;
  late BodyMeasurementProvider bodyMeasurements;
  late StrengthProvider strength;
  late CloudBackupService cloud;

  Future<void> backupNow() => cloud.backup(
        uid: _uid,
        user: user,
        workouts: workouts,
        nutrition: nutrition,
        catalog: catalog,
        weight: weight,
        bodyMeasurements: bodyMeasurements,
        strength: strength,
      );

  Future<void> restoreNow({String uid = _uid}) => cloud.restore(
        uid: uid,
        user: user,
        workouts: workouts,
        nutrition: nutrition,
        catalog: catalog,
        weight: weight,
        bodyMeasurements: bodyMeasurements,
        strength: strength,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    user = UserProvider();
    await user.load();

    workouts = WorkoutProvider();
    await workouts.load();
    for (final log in List.of(workouts.logs)) {
      if (log.id != null) await workouts.deleteLog(log.id!);
    }

    nutrition = NutritionProvider();
    await nutrition.load();

    catalog = FoodCatalogProvider();
    await catalog.load();

    weight = WeightProvider();
    await weight.load();
    for (final w in List.of(weight.logs)) {
      if (w.id != null) await weight.deleteEntry(w.id!);
    }

    bodyMeasurements = BodyMeasurementProvider();
    await bodyMeasurements.load();

    strength = StrengthProvider();
    await strength.load();
    for (final s in List.of(strength.sets)) {
      if (s.id != null) await strength.deleteSet(s.id!);
    }

    cloud = CloudBackupService(firestore: FakeFirebaseFirestore());
  });

  test('lastCloudBackupAt is null before any backup exists', () async {
    expect(await cloud.lastCloudBackupAt(_uid), isNull);
  });

  test('restore throws when this account has no cloud backup yet', () async {
    await expectLater(restoreNow(uid: 'nobody-has-backed-up'), throwsA(isA<StateError>()));
  });

  test('backup then restore round-trips workout logs through Firestore', () async {
    await workouts.addLog(
      WorkoutLog(title: 'Run', category: 'Cardio', minutes: 30, calories: 250, dateTime: DateTime(2026, 1, 1)),
    );

    await backupNow();
    expect(await cloud.lastCloudBackupAt(_uid), isNotNull);

    // Simulate a fresh install / different device: clear local data first.
    for (final log in List.of(workouts.logs)) {
      if (log.id != null) await workouts.deleteLog(log.id!);
    }
    expect(workouts.logs, isEmpty);

    await restoreNow();

    expect(workouts.logs, hasLength(1));
    expect(workouts.logs.first.title, 'Run');
  });

  test('backup then restore round-trips weight logs and profile name through Firestore', () async {
    await user.updateProfile(name: 'Cloud Tester');
    await weight.addEntry(weightKg: 71.5, dateTime: DateTime(2026, 1, 1));

    await backupNow();

    await weight.deleteEntry(weight.logs.first.id!);
    await user.updateProfile(name: 'Someone Else');
    expect(weight.logs, isEmpty);

    await restoreNow();

    expect(weight.logs, hasLength(1));
    expect(weight.logs.first.weight, 71.5);
    expect(user.name, 'Cloud Tester');
  });

  test('a second backup overwrites the first (latest wins, not appended)', () async {
    await workouts.addLog(
      WorkoutLog(title: 'First', category: 'Cardio', minutes: 10, calories: 50, dateTime: DateTime(2026, 1, 1)),
    );
    await backupNow();

    for (final log in List.of(workouts.logs)) {
      if (log.id != null) await workouts.deleteLog(log.id!);
    }
    await workouts.addLog(
      WorkoutLog(title: 'Second', category: 'Cardio', minutes: 20, calories: 100, dateTime: DateTime(2026, 1, 2)),
    );
    await backupNow();

    for (final log in List.of(workouts.logs)) {
      if (log.id != null) await workouts.deleteLog(log.id!);
    }
    await restoreNow();

    expect(workouts.logs, hasLength(1));
    expect(workouts.logs.first.title, 'Second');
  });
}
