import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
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
      version: 4,
      onCreate: (db, version) async {
        await db.execute(_createWorkoutLogs);
        await db.execute(_createFoodLogs);
        await db.execute(_createCustomFoods);
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
}
