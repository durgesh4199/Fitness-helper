import 'package:flutter/material.dart';
import '../models/strength_progress.dart';
import '../models/strength_set.dart';
import '../services/database_service.dart';

class StrengthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<StrengthSet> _sets = [];
  bool _loading = true;

  List<StrengthSet> get sets => _sets;
  bool get loading => _loading;

  Future<void> load() async {
    _sets = await _db.getAllStrengthSets();
    _loading = false;
    notifyListeners();
  }

  List<StrengthSet> setsForWorkout(int workoutLogId) {
    final matching = _sets.where((s) => s.workoutLogId == workoutLogId).toList();
    matching.sort((a, b) => a.setIndex.compareTo(b.setIndex));
    return matching;
  }

  Future<StrengthSet> addSet(StrengthSet set) async {
    final id = await _db.insertStrengthSet(set);
    final saved = set.copyWith(id: id);
    _sets = [saved, ..._sets];
    notifyListeners();
    return saved;
  }

  Future<void> deleteSet(int id) async {
    await _db.deleteStrengthSet(id);
    _sets = _sets.where((s) => s.id != id).toList();
    notifyListeners();
  }

  /// Cleans up sets belonging to a workout that's being deleted — call this
  /// alongside WorkoutProvider.deleteLog, since the two tables aren't
  /// linked by a real foreign key.
  Future<void> deleteSetsForWorkout(int workoutLogId) async {
    await _db.deleteStrengthSetsForWorkout(workoutLogId);
    _sets = _sets.where((s) => s.workoutLogId != workoutLogId).toList();
    notifyListeners();
  }

  /// Distinct exercise names logged so far (most-recently-logged first),
  /// used to speed up entry for repeat exercises.
  List<String> get knownExerciseNames {
    final seen = <String>{};
    final names = <String>[];
    for (final s in _sets) {
      if (seen.add(s.exerciseName)) names.add(s.exerciseName);
    }
    return names;
  }

  List<ExerciseProgress> get progress => ProgressiveOverloadEngine.evaluate(_sets);

  /// Replaces all strength sets with [sets] — used when restoring a backup.
  Future<void> restoreSets(List<StrengthSet> sets) async {
    await _db.clearAndInsertStrengthSets(sets);
    await load();
  }
}
