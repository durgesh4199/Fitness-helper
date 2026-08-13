import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'diet_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'workouts_screen.dart';
import '../providers/body_measurement_provider.dart';
import '../providers/food_catalog_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/workout_provider.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    WorkoutsScreen(),
    DietScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  final _navItems = const [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.fitness_center_rounded, label: 'Workouts'),
    (icon: Icons.restaurant_rounded, label: 'Diet'),
    (icon: Icons.bar_chart_rounded, label: 'Progress'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoBackup());
  }

  Future<void> _maybeAutoBackup() async {
    if (!await BackupService.isAutoBackupDue()) return;
    if (!mounted) return;
    await BackupService.shareBackup(
      user: context.read<UserProvider>(),
      workouts: context.read<WorkoutProvider>(),
      nutrition: context.read<NutritionProvider>(),
      catalog: context.read<FoodCatalogProvider>(),
      weight: context.read<WeightProvider>(),
      bodyMeasurements: context.read<BodyMeasurementProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildNavBar(context.colors),
    );
  }

  Widget _buildNavBar(AppPalette colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: colors.shadow, blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: List.generate(_navItems.length, (i) {
          final selected = _index == i;
          final item = _navItems[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _index = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? colors.primary.withValues(alpha: 0.14) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
