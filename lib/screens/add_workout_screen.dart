import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mock_data.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  late WorkoutCategory _category = MockData.categories.first;
  final _titleController = TextEditingController();
  final _minutesController = TextEditingController(text: '30');
  final _caloriesController = TextEditingController(text: '200');

  @override
  void dispose() {
    _titleController.dispose();
    _minutesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      (int.tryParse(_minutesController.text) ?? 0) > 0 &&
      (int.tryParse(_caloriesController.text) ?? 0) > 0;

  Future<void> _save() async {
    final log = WorkoutLog(
      title: _titleController.text.trim(),
      category: _category.name,
      minutes: int.parse(_minutesController.text),
      calories: int.parse(_caloriesController.text),
      dateTime: DateTime.now(),
    );
    await context.read<WorkoutProvider>().addLog(log);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Log a workout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = MockData.categories[index];
                  final selected = _category.name == cat.name;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      width: 76,
                      decoration: BoxDecoration(
                        color: selected ? cat.color : colors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon, color: selected ? Colors.white : cat.color, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _field(colors, 'Workout name', _titleController, TextInputType.text),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field(colors, 'Minutes', _minutesController, TextInputType.number)),
                const SizedBox(width: 14),
                Expanded(child: _field(colors, 'Calories burned', _caloriesController, TextInputType.number)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.primary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save workout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(AppPalette colors, String hint, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
