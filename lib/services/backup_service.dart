import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
import '../models/workout_log.dart';
import '../providers/food_catalog_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';

/// Exports/imports all user data (profile, workout logs, food logs, custom
/// foods) as a single JSON file, shared via the native share sheet so it can
/// be saved somewhere that survives an app uninstall (Drive, email, Files) —
/// unlike the app's own storage, which Android/iOS wipe on uninstall.
class BackupService {
  BackupService._();

  static const _kLastBackupAt = 'last_backup_at';
  static const autoBackupInterval = Duration(days: 7);
  static const _formatVersion = 1;

  /// Whether enough time has passed since the last backup (or none has ever
  /// been taken) to trigger another automatic one.
  static Future<bool> isAutoBackupDue() async {
    final last = await lastBackupAt();
    if (last == null) return true;
    return DateTime.now().difference(last) >= autoBackupInterval;
  }

  static Future<DateTime?> lastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIso = prefs.getString(_kLastBackupAt);
    return lastIso == null ? null : DateTime.tryParse(lastIso);
  }

  static Future<void> _markBackedUpNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackupAt, DateTime.now().toIso8601String());
  }

  static Map<String, Object?> _buildSnapshot({
    required UserProvider user,
    required WorkoutProvider workouts,
    required NutritionProvider nutrition,
    required FoodCatalogProvider catalog,
  }) {
    return {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': user.toBackupMap(),
      'workoutLogs': workouts.logs.map((l) => l.toMap()).toList(),
      'foodLogs': nutrition.logs.map((l) => l.toMap()).toList(),
      'customFoods': catalog.customItems.map((f) => f.toMap()).toList(),
    };
  }

  /// Builds a backup file in the temp directory and opens the native share
  /// sheet so the user can save it anywhere. Marks the backup as done
  /// regardless of whether the user completes the share, so a dismissed
  /// periodic prompt doesn't nag again immediately — the manual "Back up
  /// now" button in Profile is always there if they want to retry.
  static Future<void> shareBackup({
    required UserProvider user,
    required WorkoutProvider workouts,
    required NutritionProvider nutrition,
    required FoodCatalogProvider catalog,
  }) async {
    final snapshot = _buildSnapshot(user: user, workouts: workouts, nutrition: nutrition, catalog: catalog);
    final json = const JsonEncoder.withIndent('  ').convert(snapshot);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/fitness_tracker_backup_$stamp.json');
    await file.writeAsString(json);

    await _markBackedUpNow();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Fitness Tracker backup',
      text: 'Your Fitness Tracker data backup from $stamp. Keep this file '
          'somewhere safe — restoring it will bring back your workouts, '
          'food logs, and profile even after reinstalling the app.',
    );
  }

  /// Reads a previously exported backup file and restores it into the app,
  /// replacing all current workout logs, food logs, custom foods, and
  /// profile settings.
  static Future<void> restoreFromFile({
    required String path,
    required UserProvider user,
    required WorkoutProvider workouts,
    required NutritionProvider nutrition,
    required FoodCatalogProvider catalog,
  }) async {
    final content = await File(path).readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final profile = ((data['profile'] as Map?) ?? const {}).cast<String, Object?>();
    await user.restoreProfile(profile);

    final workoutLogs = ((data['workoutLogs'] as List?) ?? const [])
        .map((m) => WorkoutLog.fromMap((m as Map).cast<String, Object?>()))
        .toList();
    await workouts.restoreLogs(workoutLogs);

    final foodLogs = ((data['foodLogs'] as List?) ?? const [])
        .map((m) => FoodLog.fromMap((m as Map).cast<String, Object?>()))
        .toList();
    await nutrition.restoreLogs(foodLogs);

    final customFoods = ((data['customFoods'] as List?) ?? const [])
        .map((m) => FoodItem.fromMap((m as Map).cast<String, Object?>()))
        .toList();
    await catalog.restoreCustomFoods(customFoods);
  }
}
