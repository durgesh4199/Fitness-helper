import 'package:flutter/material.dart';
import 'workout.dart';
import '../theme/app_theme.dart';

class MockData {
  MockData._();

  static const categories = [
    WorkoutCategory(name: 'Cardio', icon: Icons.directions_run_rounded, color: AppBrand.accentOrange),
    WorkoutCategory(name: 'Strength', icon: Icons.fitness_center_rounded, color: AppBrand.secondary),
    WorkoutCategory(name: 'Yoga', icon: Icons.self_improvement_rounded, color: AppBrand.accentPink),
    WorkoutCategory(name: 'Cycling', icon: Icons.pedal_bike_rounded, color: AppBrand.accentBlue),
  ];

  static const workouts = [
    Workout(
      title: 'Morning Run',
      category: 'Cardio',
      icon: Icons.directions_run_rounded,
      color: AppBrand.accentOrange,
      minutes: 30,
      calories: 280,
    ),
    Workout(
      title: 'Full Body Strength',
      category: 'Strength',
      icon: Icons.fitness_center_rounded,
      color: AppBrand.secondary,
      minutes: 45,
      calories: 320,
    ),
    Workout(
      title: 'Sunrise Yoga Flow',
      category: 'Yoga',
      icon: Icons.self_improvement_rounded,
      color: AppBrand.accentPink,
      minutes: 20,
      calories: 110,
    ),
    Workout(
      title: 'Hill Cycling',
      category: 'Cycling',
      icon: Icons.pedal_bike_rounded,
      color: AppBrand.accentBlue,
      minutes: 40,
      calories: 350,
    ),
    Workout(
      title: 'Core & Abs Blast',
      category: 'Strength',
      icon: Icons.sports_gymnastics_rounded,
      color: AppBrand.primary,
      minutes: 25,
      calories: 190,
    ),
    Workout(
      title: 'HIIT Sprint',
      category: 'Cardio',
      icon: Icons.bolt_rounded,
      color: AppBrand.accentOrange,
      minutes: 20,
      calories: 260,
    ),
  ];

  static const weeklyActivity = [
    DailyActivity(label: 'Mon', value: 0.4),
    DailyActivity(label: 'Tue', value: 0.65),
    DailyActivity(label: 'Wed', value: 0.5),
    DailyActivity(label: 'Thu', value: 0.9),
    DailyActivity(label: 'Fri', value: 0.7),
    DailyActivity(label: 'Sat', value: 1.0),
    DailyActivity(label: 'Sun', value: 0.3),
  ];
}
