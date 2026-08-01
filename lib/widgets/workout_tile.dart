import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../theme/app_theme.dart';

class WorkoutTile extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onTap;

  const WorkoutTile({super.key, required this.workout, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: workout.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(workout.icon, color: workout.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.minutes} min',
                          style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.local_fire_department_rounded, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.calories} kcal',
                          style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
