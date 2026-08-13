import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/strength_set.dart';
import '../providers/strength_provider.dart';
import '../theme/app_theme.dart';

/// Lets the user log individual sets (exercise / reps / weight) against a
/// specific workout entry. Reachable both right after saving a Strength
/// workout and later by tapping that workout in history, so sets can be
/// added or reviewed at any time.
class LogSetsScreen extends StatefulWidget {
  final int workoutLogId;
  final String workoutTitle;

  const LogSetsScreen({super.key, required this.workoutLogId, required this.workoutTitle});

  @override
  State<LogSetsScreen> createState() => _LogSetsScreenState();
}

class _LogSetsScreenState extends State<LogSetsScreen> {
  final _exerciseController = TextEditingController();
  final _exerciseFocusNode = FocusNode();
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _exerciseController.dispose();
    _exerciseFocusNode.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _canAdd =>
      _exerciseController.text.trim().isNotEmpty && (int.tryParse(_repsController.text) ?? 0) > 0;

  Future<void> _addSet() async {
    final provider = context.read<StrengthProvider>();
    final existing = provider.setsForWorkout(widget.workoutLogId);
    final nextIndex =
        existing.isEmpty ? 1 : existing.map((s) => s.setIndex).reduce((a, b) => a > b ? a : b) + 1;

    await provider.addSet(StrengthSet(
      workoutLogId: widget.workoutLogId,
      exerciseName: _exerciseController.text.trim(),
      setIndex: nextIndex,
      reps: int.parse(_repsController.text),
      weightKg: double.tryParse(_weightController.text),
      dateTime: DateTime.now(),
    ));

    _repsController.text = '10';
    _weightController.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sets = context.watch<StrengthProvider>().setsForWorkout(widget.workoutLogId);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text('Sets · ${widget.workoutTitle}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: sets.isEmpty
                  ? Center(
                      child: Text('No sets logged yet.', style: TextStyle(color: colors.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: sets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _SetTile(set: sets[index], colors: colors),
                    ),
            ),
            _buildEntryForm(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm(AppPalette colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<String>(
            textEditingController: _exerciseController,
            focusNode: _exerciseFocusNode,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              final known = context.read<StrengthProvider>().knownExerciseNames;
              if (query.isEmpty) return known;
              return known.where((n) => n.toLowerCase().contains(query));
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Exercise name',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _numberField(colors, 'Reps', _repsController)),
              const SizedBox(width: 10),
              Expanded(child: _numberField(colors, 'Weight (kg, optional)', _weightController)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _canAdd ? _addSet : null,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add set', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(AppPalette colors, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: colors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  final StrengthSet set;
  final AppPalette colors;

  const _SetTile({required this.set, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<StrengthProvider>().deleteSet(set.id!),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Text('${set.setIndex}', style: TextStyle(fontWeight: FontWeight.w800, color: colors.primary, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(set.exerciseName, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    set.weightKg != null
                        ? '${set.reps} reps · ${set.weightKg!.toStringAsFixed(1)} kg'
                        : '${set.reps} reps · bodyweight',
                    style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
