import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum HeightUnit { cm, ftIn }

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  final _nameController = TextEditingController();
  final _cmController = TextEditingController(text: '172');
  final _feetController = TextEditingController(text: '5');
  final _inchController = TextEditingController(text: '8');
  final _weightController = TextEditingController(text: '70');
  final _goalController = TextEditingController(text: '65');
  final _ageController = TextEditingController(text: '25');

  HeightUnit _heightUnit = HeightUnit.cm;
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cmController.dispose();
    _feetController.dispose();
    _inchController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  double? _heightCm() {
    if (_heightUnit == HeightUnit.cm) {
      final cm = double.tryParse(_cmController.text);
      return (cm != null && cm > 0) ? cm : null;
    }
    final ft = double.tryParse(_feetController.text) ?? 0;
    final inch = double.tryParse(_inchController.text) ?? 0;
    final cm = (ft * 12 + inch) * 2.54;
    return cm > 0 ? cm : null;
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim().isEmpty ? 'Friend' : _nameController.text.trim();
    final height = _heightCm() ?? 172;
    final weight = double.tryParse(_weightController.text) ?? 70;
    final goal = double.tryParse(_goalController.text) ?? weight;
    final age = (int.tryParse(_ageController.text) ?? 25).clamp(10, 100);

    await context.read<UserProvider>().completeOnboarding(
          name: name,
          heightCm: height,
          weightKg: weight,
          goalWeightKg: goal,
          age: age,
          sex: _sex,
          activity: _activity,
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  bool get _canContinue {
    switch (_page) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        final w = double.tryParse(_weightController.text);
        final a = int.tryParse(_ageController.text);
        return _heightCm() != null && w != null && w > 0 && a != null && a > 0;
      default:
        final g = double.tryParse(_goalController.text);
        return g != null && g > 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildProgressDots(colors),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _NameStep(controller: _nameController, onChanged: () => setState(() {})),
                  _HeightWeightStep(
                    heightUnit: _heightUnit,
                    onUnitChanged: (u) => setState(() => _heightUnit = u),
                    cmController: _cmController,
                    feetController: _feetController,
                    inchController: _inchController,
                    weightController: _weightController,
                    ageController: _ageController,
                    sex: _sex,
                    onSexChanged: (s) => setState(() => _sex = s),
                    onChanged: () => setState(() {}),
                  ),
                  _GoalStep(
                    controller: _goalController,
                    activity: _activity,
                    onActivityChanged: (a) => setState(() => _activity = a),
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: _back,
                      child: Text('Back', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canContinue ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _page == 2 ? 'Get started' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(AppPalette colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.textSecondary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.gradientStart, colors.gradientEnd]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NameStep({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.waving_hand_rounded,
      title: 'Welcome! What should we call you?',
      subtitle: 'This personalizes your dashboard and greetings.',
      children: [
        _OnboardingField(
          controller: controller,
          hint: 'Your name',
          keyboardType: TextInputType.name,
          onChanged: onChanged,
        ),
        const SizedBox(height: 28),
        const _ThemeChoice(),
      ],
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mode = context.watch<ThemeProvider>().themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose your look',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            _ThemePreviewCard(
              label: 'System',
              mode: ThemeMode.system,
              selected: mode == ThemeMode.system,
              bg: colors.background,
              cardColor: colors.surface,
              accent: colors.primary,
              split: true,
            ),
            const SizedBox(width: 12),
            _ThemePreviewCard(
              label: 'Light',
              mode: ThemeMode.light,
              selected: mode == ThemeMode.light,
              bg: const Color(0xFFF6F5FB),
              cardColor: Colors.white,
              accent: const Color(0xFF7C5CFF),
            ),
            const SizedBox(width: 12),
            _ThemePreviewCard(
              label: 'Dark',
              mode: ThemeMode.dark,
              selected: mode == ThemeMode.dark,
              bg: const Color(0xFF0B0912),
              cardColor: const Color(0xFF171320),
              accent: const Color(0xFFA98BFF),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final bool selected;
  final Color bg;
  final Color cardColor;
  final Color accent;
  final bool split;

  const _ThemePreviewCard({
    required this.label,
    required this.mode,
    required this.selected,
    required this.bg,
    required this.cardColor,
    required this.accent,
    this.split = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ThemeProvider>().setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.18),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Mini mockup preview.
              AspectRatio(
                aspectRatio: 1.15,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: split
                            ? Row(
                                children: [
                                  Expanded(child: Container(color: const Color(0xFFF6F5FB))),
                                  Expanded(child: Container(color: const Color(0xFF0B0912))),
                                ],
                              )
                            : Container(color: bg),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 6,
                              width: 26,
                              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 14,
                              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(4)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 14,
                              width: 30,
                              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 15,
                    color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeightWeightStep extends StatelessWidget {
  final HeightUnit heightUnit;
  final ValueChanged<HeightUnit> onUnitChanged;
  final TextEditingController cmController;
  final TextEditingController feetController;
  final TextEditingController inchController;
  final TextEditingController weightController;
  final TextEditingController ageController;
  final Sex sex;
  final ValueChanged<Sex> onSexChanged;
  final VoidCallback onChanged;

  const _HeightWeightStep({
    required this.heightUnit,
    required this.onUnitChanged,
    required this.cmController,
    required this.feetController,
    required this.inchController,
    required this.weightController,
    required this.ageController,
    required this.sex,
    required this.onSexChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _StepScaffold(
      icon: Icons.straighten_rounded,
      title: 'A bit about your body',
      subtitle: 'Used to calculate your BMI and personalize your daily targets.',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Height', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            _UnitToggle(
              options: const ['cm', 'ft/in'],
              selectedIndex: heightUnit == HeightUnit.cm ? 0 : 1,
              onSelect: (i) => onUnitChanged(i == 0 ? HeightUnit.cm : HeightUnit.ftIn),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (heightUnit == HeightUnit.cm)
          _UnitField(controller: cmController, unit: 'cm', hint: '172', onChanged: onChanged)
        else
          Row(
            children: [
              Expanded(child: _UnitField(controller: feetController, unit: 'ft', hint: '5', onChanged: onChanged)),
              const SizedBox(width: 12),
              Expanded(child: _UnitField(controller: inchController, unit: 'in', hint: '8', onChanged: onChanged)),
            ],
          ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 10),
                  _UnitField(controller: weightController, unit: 'kg', hint: '70', onChanged: onChanged),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Age', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 10),
                  _UnitField(controller: ageController, unit: 'yrs', hint: '25', onChanged: onChanged),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Sex', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ChoicePill(
                label: 'Male',
                icon: Icons.male_rounded,
                selected: sex == Sex.male,
                onTap: () => onSexChanged(Sex.male),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoicePill(
                label: 'Female',
                icon: Icons.female_rounded,
                selected: sex == Sex.female,
                onTap: () => onSexChanged(Sex.female),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sex and age affect calorie, protein, iron & calcium needs.',
          style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  final TextEditingController controller;
  final ActivityLevel activity;
  final ValueChanged<ActivityLevel> onActivityChanged;
  final VoidCallback onChanged;

  const _GoalStep({
    required this.controller,
    required this.activity,
    required this.onActivityChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _StepScaffold(
      icon: Icons.flag_rounded,
      title: 'Goal & activity',
      subtitle: 'We\'ll set your daily calories and macros from this.',
      children: [
        Text('Goal weight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 10),
        _UnitField(controller: controller, unit: 'kg', hint: '65', onChanged: onChanged),
        const SizedBox(height: 22),
        Text('How active are you?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 10),
        ...ActivityLevel.values.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityRow(
                level: a,
                selected: activity == a,
                onTap: () => onActivityChanged(a),
              ),
            )),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : colors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityRow({required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.12) : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  Text(level.hint, style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A segmented pill toggle (e.g. cm / ft-in).
class _UnitToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _UnitToggle({required this.options, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A number field with a trailing unit badge.
class _UnitField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String hint;
  final VoidCallback onChanged;

  const _UnitField({required this.controller, required this.unit, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (_) => onChanged(),
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Text(
            unit,
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _OnboardingField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final VoidCallback onChanged;

  const _OnboardingField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged(),
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
