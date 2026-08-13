import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
import '../models/weight_log.dart';
import '../models/water_log.dart';
import '../models/workout_log.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _init();
    return _database!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'fitness_tracker.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute(_createWorkoutLogs);
        await db.execute(_createFoodLogs);
        await db.execute(_createCustomFoods);
        await db.execute(_createWeightLogs);
        await db.execute(_createWaterLogs);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createFoodLogsV2);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE food_logs ADD COLUMN sugar REAL NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE food_logs ADD COLUMN caffeine REAL NOT NULL DEFAULT 0');
        }
        if (oldVersion < 4) {
          await db.execute(_createCustomFoods);
        }
        if (oldVersion < 5) {
          // Additive only — existing tables/data are untouched.
          await db.execute(_createWeightLogs);
          await db.execute(_createWaterLogs);
        }
      },
    );
  }

  static const _createWorkoutLogs = '''
    CREATE TABLE workout_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      minutes INTEGER NOT NULL,
      calories INTEGER NOT NULL,
      date_time TEXT NOT NULL
    )
  ''';

  static const _createFoodLogs = '''
    CREATE TABLE food_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      meal TEXT NOT NULL,
      servings REAL NOT NULL,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fiber REAL NOT NULL,
      fat REAL NOT NULL,
      sugar REAL NOT NULL DEFAULT 0,
      iron REAL NOT NULL,
      calcium REAL NOT NULL,
      vitamin_c REAL NOT NULL,
      caffeine REAL NOT NULL DEFAULT 0,
      date_time TEXT NOT NULL
    )
  ''';

  // Original v2 food_logs schema (without sugar/caffeine), used only when
  // upgrading a very old database; the v3 step then adds the new columns.
  static const _createFoodLogsV2 = '''
    CREATE TABLE food_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      meal TEXT NOT NULL,
      servings REAL NOT NULL,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fiber REAL NOT NULL,
      fat REAL NOT NULL,
      iron REAL NOT NULL,
      calcium REAL NOT NULL,
      vitamin_c REAL NOT NULL,
      date_time TEXT NOT NULL
    )
  ''';

  // User-imported/added reference foods, merged with the built-in catalog at
  // read time (see FoodCatalogProvider). Unique on (name, category) so
  // re-importing an unmodified export doesn't create duplicates.
  static const _createCustomFoods = '''
    CREATE TABLE custom_foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      serving TEXT NOT NULL,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fiber REAL NOT NULL,
      fat REAL NOT NULL,
      sugar REAL NOT NULL DEFAULT 0,
      iron REAL NOT NULL DEFAULT 0,
      calcium REAL NOT NULL DEFAULT 0,
      vitamin_c REAL NOT NULL DEFAULT 0,
      caffeine REAL NOT NULL DEFAULT 0,
      UNIQUE(name, category)
    )
  ''';

  // Historical weight (and optional body-fat) entries — separate from the
  // single "current weight" kept on the profile, so trends/averages/charts
  // are possible. `source` distinguishes a real entry from anything the app
  // might import automatically in the future (see HealthDataSource).
  static const _createWeightLogs = '''
    CREATE TABLE weight_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight REAL NOT NULL,
      body_fat REAL,
      date_time TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT 'userEntered',
      notes TEXT
    )
  ''';

  // Individual water-intake entries. `UserProvider.waterIntakeMl` remains
  // the fast running-total for "today" (SharedPreferences); these rows exist
  // to support history/weekly-average features without changing that.
  static const _createWaterLogs = '''
    CREATE TABLE water_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount_ml INTEGER NOT NULL,
      date_time TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT 'userEntered'
    )
  ''';

  // ---- Workout logs ----
  Future<int> insertLog(WorkoutLog log) async {
    final db = await database;
    return db.insert('workout_logs', log.toMap()..remove('id'));
  }

  Future<List<WorkoutLog>> getAllLogs() async {
    final db = await database;
    final rows = await db.query('workout_logs', orderBy: 'date_time DESC');
    return rows.map(WorkoutLog.fromMap).toList();
  }

  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Food logs ----
  Future<int> insertFoodLog(FoodLog log) async {
    final db = await database;
    return db.insert('food_logs', log.toMap()..remove('id'));
  }

  Future<List<FoodLog>> getAllFoodLogs() async {
    final db = await database;
    final rows = await db.query('food_logs', orderBy: 'date_time DESC');
    return rows.map(FoodLog.fromMap).toList();
  }

  Future<void> deleteFoodLog(int id) async {
    final db = await database;
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Custom foods (imported / user-added reference items) ----
  Future<List<FoodItem>> getAllCustomFoods() async {
    final db = await database;
    final rows = await db.query('custom_foods', orderBy: 'name COLLATE NOCASE');
    return rows.map(FoodItem.fromMap).toList();
  }

  /// Inserts a new custom food, or updates the existing one with the same
  /// (name, category) if present. Returns true if it was an insert, false if
  /// it updated an existing row.
  Future<bool> upsertCustomFood(FoodItem item) async {
    final db = await database;
    final existing = await db.query(
      'custom_foods',
      where: 'name = ? COLLATE NOCASE AND category = ? COLLATE NOCASE',
      whereArgs: [item.name, item.category],
      limit: 1,
    );
    final map = item.toMap()..remove('id');
    if (existing.isEmpty) {
      await db.insert('custom_foods', map);
      return true;
    } else {
      await db.update('custom_foods', map, where: 'id = ?', whereArgs: [existing.first['id']]);
      return false;
    }
  }

  Future<void> deleteCustomFood(int id) async {
    final db = await database;
    await db.delete('custom_foods', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Bulk replace, used by backup restore ----

  Future<void> clearAndInsertWorkoutLogs(List<WorkoutLog> logs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('workout_logs');
      for (final log in logs) {
        await txn.insert('workout_logs', log.toMap()..remove('id'));
      }
    });
  }

  Future<void> clearAndInsertFoodLogs(List<FoodLog> logs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('food_logs');
      for (final log in logs) {
        await txn.insert('food_logs', log.toMap()..remove('id'));
      }
    });
  }

  Future<void> clearAndInsertCustomFoods(List<FoodItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('custom_foods');
      for (final item in items) {
        await txn.insert('custom_foods', item.toMap()..remove('id'));
      }
    });
  }

  // ---- Weight logs ----
  Future<int> insertWeightLog(WeightLog log) async {
    final db = await database;
    return db.insert('weight_logs', log.toMap()..remove('id'));
  }

  Future<List<WeightLog>> getAllWeightLogs() async {
    final db = await database;
    final rows = await db.query('weight_logs', orderBy: 'date_time DESC');
    return rows.map(WeightLog.fromMap).toList();
  }

  Future<void> deleteWeightLog(int id) async {
    final db = await database;
    await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAndInsertWeightLogs(List<WeightLog> logs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('weight_logs');
      for (final log in logs) {
        await txn.insert('weight_logs', log.toMap()..remove('id'));
      }
    });
  }

  // ---- Water logs ----
  Future<int> insertWaterLog(WaterLog log) async {
    final db = await database;
    return db.insert('water_logs', log.toMap()..remove('id'));
  }

  Future<List<WaterLog>> getAllWaterLogs() async {
    final db = await database;
    final rows = await db.query('water_logs', orderBy: 'date_time DESC');
    return rows.map(WaterLog.fromMap).toList();
  }

  Future<void> deleteWaterLog(int id) async {
    final db = await database;
    await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAndInsertWaterLogs(List<WaterLog> logs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('water_logs');
      for (final log in logs) {
        await txn.insert('water_logs', log.toMap()..remove('id'));
      }
    });
  }
}
