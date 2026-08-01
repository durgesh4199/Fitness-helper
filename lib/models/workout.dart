import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Maps a category name to a fixed, statically-known icon/color so that
/// persisted logs (which only store the category as a string) can render
/// without needing to serialize arbitrary IconData (which would defeat icon
/// tree-shaking in release builds).
IconData categoryIcon(String category) {
  switch (category) {
    case 'Cardio':
      return Icons.directions_run_rounded;
    case 'Strength':
      return Icons.fitness_center_rounded;
    case 'Yoga':
      return Icons.self_improvement_rounded;
    case 'Cycling':
      return Icons.pedal_bike_rounded;
    default:
      return Icons.sports_gymnastics_rounded;
  }
}

Color categoryColor(String category) {
  switch (category) {
    case 'Cardio':
      return AppBrand.accentOrange;
    case 'Strength':
      return AppBrand.secondary;
    case 'Yoga':
      return AppBrand.accentPink;
    case 'Cycling':
      return AppBrand.accentBlue;
    default:
      return AppBrand.primary;
  }
}

class WorkoutCategory {
  final String name;
  final IconData icon;
  final Color color;

  const WorkoutCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Workout {
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final int minutes;
  final int calories;

  const Workout({
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.minutes,
    required this.calories,
  });
}

class DailyActivity {
  final String label;
  final double value;

  const DailyActivity({required this.label, required this.value});
}
