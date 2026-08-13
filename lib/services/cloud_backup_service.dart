import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/body_measurement_provider.dart';
import '../providers/food_catalog_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/strength_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/workout_provider.dart';
import 'backup_service.dart';

/// Cloud counterpart to [BackupService]'s local file export — pushes/pulls
/// the identical JSON-shaped snapshot to a single Firestore document scoped
/// to the signed-in user's uid, so data survives a reinstall and is tied to
/// an account rather than a device.
///
/// Note: Firestore documents are capped at 1MiB. A very long logging
/// history could theoretically approach that; the local file backup (which
/// has no such limit) remains the primary backup path for that case.
class CloudBackupService {
  CloudBackupService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('backup').doc('latest');

  Future<void> backup({
    required String uid,
    required UserProvider user,
    required WorkoutProvider workouts,
    required NutritionProvider nutrition,
    required FoodCatalogProvider catalog,
    required WeightProvider weight,
    required BodyMeasurementProvider bodyMeasurements,
    required StrengthProvider strength,
  }) async {
    final snapshot = await BackupService.buildSnapshot(
      user: user,
      workouts: workouts,
      nutrition: nutrition,
      catalog: catalog,
      weight: weight,
      bodyMeasurements: bodyMeasurements,
      strength: strength,
    );
    await _doc(uid).set(snapshot);
  }

  /// Null if this account has never backed up to the cloud.
  Future<DateTime?> lastCloudBackupAt(String uid) async {
    final doc = await _doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    final createdAt = data['createdAt'] as String?;
    return createdAt == null ? null : DateTime.tryParse(createdAt);
  }

  Future<void> restore({
    required String uid,
    required UserProvider user,
    required WorkoutProvider workouts,
    required NutritionProvider nutrition,
    required FoodCatalogProvider catalog,
    required WeightProvider weight,
    required BodyMeasurementProvider bodyMeasurements,
    required StrengthProvider strength,
  }) async {
    final doc = await _doc(uid).get();
    final data = doc.data();
    if (data == null) {
      throw StateError('No cloud backup found for this account yet.');
    }
    await BackupService.restoreFromSnapshot(
      data,
      user: user,
      workouts: workouts,
      nutrition: nutrition,
      catalog: catalog,
      weight: weight,
      bodyMeasurements: bodyMeasurements,
      strength: strength,
    );
  }
}
