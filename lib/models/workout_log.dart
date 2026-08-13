import 'package:flutter/material.dart';
import 'workout.dart';

class WorkoutLog {
  final int? id;
  final String title;
  final String category;
  final int minutes;
  final int calories;
  final DateTime dateTime;

  /// Rate of Perceived Exertion (1-10), optional — how hard the workout
  /// felt, not a medical assessment. Null when the user skipped it.
  final int? rpe;

  const WorkoutLog({
    this.id,
    required this.title,
    required this.category,
    required this.minutes,
    required this.calories,
    required this.dateTime,
    this.rpe,
  });

  IconData get icon => categoryIcon(category);
  Color get color => categoryColor(category);

  /// Simple training-load metric (duration x RPE) — a relative number for
  /// comparing sessions/weeks, not a clinical measurement. Null without RPE.
  int? get trainingLoad => rpe == null ? null : minutes * rpe!;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'minutes': minutes,
      'calories': calories,
      'date_time': dateTime.toIso8601String(),
      'rpe': rpe,
    };
  }

  factory WorkoutLog.fromMap(Map<String, Object?> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      minutes: map['minutes'] as int,
      calories: map['calories'] as int,
      dateTime: DateTime.parse(map['date_time'] as String),
      rpe: map['rpe'] as int?,
    );
  }

  WorkoutLog copyWith({int? id}) {
    return WorkoutLog(
      id: id ?? this.id,
      title: title,
      category: category,
      minutes: minutes,
      calories: calories,
      dateTime: dateTime,
      rpe: rpe,
    );
  }
}
