import 'package:flutter/material.dart';
import 'workout.dart';

class WorkoutLog {
  final int? id;
  final String title;
  final String category;
  final int minutes;
  final int calories;
  final DateTime dateTime;

  const WorkoutLog({
    this.id,
    required this.title,
    required this.category,
    required this.minutes,
    required this.calories,
    required this.dateTime,
  });

  IconData get icon => categoryIcon(category);
  Color get color => categoryColor(category);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'minutes': minutes,
      'calories': calories,
      'date_time': dateTime.toIso8601String(),
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
    );
  }
}
