import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/nutrition_targets.dart';
import '../providers/nutrition_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<UserProvider>();
    final nutrition = context.watch<NutritionProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 20),
          _buildProfileCard(context, colors, user),
          const SizedBox(height: 24),
          _buildStatsRow(colors, user),
          const SizedBox(height: 24),
          _buildTargetsCard(colors, user, nutrition.todayTotals),
          const SizedBox(height: 28),
          _sectionLabel(colors, 'Appearance'),
          const SizedBox(height: 10),
          const _ThemeSelector(),
          const SizedBox(height: 24),
          _sectionLabel(colors, 'Account'),
          const SizedBox(height: 10),
          _settingsGroup(context, colors, [
            _SettingItem(Icons.person_outline_rounded, 'Personal details', colors.secondary,
                onTap: () => _showEditProfileSheet(context, user)),
            _SettingItem(Icons.flag_outlined, 'Fitness goals', colors.accentOrange,
                onTap: () => _showEditProfileSheet(context, user)),
            _SettingItem(Icons.notifications_none_rounded, 'Notifications', colors.accentBlue),
          ]),
          const SizedBox(height: 24),
          _sectionLabel(colors, 'Preferences'),
          const SizedBox(height: 10),
          _settingsGroup(context, colors, [
            _SettingItem(Icons.straighten_rounded, 'Units (Metric)', colors.primary),
            _SettingItem(Icons.privacy_tip_outlined, 'Privacy', colors.accentPink),
          ]),
          const SizedBox(height: 24),
          _sectionLabel(colors, 'Support'),
          const SizedBox(height: 10),
          _settingsGroup(context, colors, [
            _SettingItem(Icons.help_outline_rounded, 'Help center', colors.secondary),
            _SettingItem(Icons.logout_rounded, 'Log out', Colors.redAccent),
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppPalette colors, UserProvider user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.gradientStart, colors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'BMI ${user.bmi.toStringAsFixed(1)} · ${user.bmiCategory}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileSheet(context, user),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppPalette colors, UserProvider user) {
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          stat('${user.weightKg.toStringAsFixed(1)} kg', 'Weight'),
          Container(width: 1, height: 30, color: colors.background),
          stat('${user.heightCm.toStringAsFixed(0)} cm', 'Height'),
          Container(width: 1, height: 30, color: colors.background),
          stat(user.bmi.toStringAsFixed(1), 'BMI'),
        ],
      ),
    );
  }

  Widget _buildTargetsCard(AppPalette colors, UserProvider user, NutritionTotals totals) {
    final t = NutritionTargets.forUser(user);

    double pct(num achieved, num goal) => goal <= 0 ? 0.0 : (achieved / goal).clamp(0.0, 1.0);

    Widget target(IconData icon, Color color, String value, String label, double percent) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 1),
              Text(label, style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 3),
              Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text('Your Daily Targets',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(t.goalLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculated from your age, sex, weight, height & activity. Bars show today\'s progress.',
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              target(Icons.local_fire_department_rounded, AppBrand.calories, '${t.calories}', 'kcal', pct(totals.calories, t.calories)),
              target(Icons.fitness_center_rounded, AppBrand.protein, '${t.protein}g', 'Protein', pct(totals.protein, t.protein)),
              target(Icons.grain_rounded, AppBrand.carbs, '${t.carbs}g', 'Carbs', pct(totals.carbs, t.carbs)),
              target(Icons.water_drop_rounded, AppBrand.fat, '${t.fat}g', 'Fat', pct(totals.fat, t.fat)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              target(Icons.eco_rounded, AppBrand.fiber, '${t.fiber}g', 'Fiber', pct(totals.fiber, t.fiber)),
              target(Icons.bloodtype_rounded, AppBrand.accentPink, '${t.iron}mg', 'Iron', pct(totals.iron, t.iron)),
              target(Icons.spa_rounded, AppBrand.accentBlue, '${t.calcium}mg', 'Calcium', pct(totals.calcium, t.calcium)),
              target(Icons.local_drink_rounded, AppBrand.accentBlue, '${(t.waterMl / 1000).toStringAsFixed(1)}L', 'Water', pct(user.waterIntakeMl, t.waterMl)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppPalette colors, String text) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
      );

  Widget _settingsGroup(BuildContext context, AppPalette colors, List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                ListTile(
                  onTap: item.onTap ?? () {},
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                ),
                if (index != items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: colors.background),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, UserProvider user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeProvider = context.watch<ThemeProvider>();

    Widget option(ThemeMode mode, IconData icon, String label) {
      final selected = themeProvider.themeMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => context.read<ThemeProvider>().setThemeMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : colors.textSecondary),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          option(ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
          option(ThemeMode.light, Icons.light_mode_rounded, 'Light'),
          option(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserProvider user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _heightController = TextEditingController(text: widget.user.heightCm.toStringAsFixed(0));
  late final _weightController = TextEditingController(text: widget.user.weightKg.toStringAsFixed(1));
  late final _goalController = TextEditingController(text: widget.user.goalWeightKg.toStringAsFixed(1));
  late final _ageController = TextEditingController(text: widget.user.age.toString());
  late Sex _sex = widget.user.sex;
  late ActivityLevel _activity = widget.user.activity;
  late bool _isDiabetic = widget.user.isDiabetic;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.user.updateProfile(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
      goalWeightKg: double.tryParse(_goalController.text),
      age: int.tryParse(_ageController.text),
      sex: _sex,
      activity: _activity,
      isDiabetic: _isDiabetic,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(colors, 'Name', _nameController, TextInputType.name),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(colors, 'Height (cm)', _heightController, const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 12),
                        Expanded(child: _field(colors, 'Weight (kg)', _weightController, const TextInputType.numberWithOptions(decimal: true))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(colors, 'Goal weight (kg)', _goalController, const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 12),
                        Expanded(child: _field(colors, 'Age', _ageController, TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Sex', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _sexPill(colors, 'Male', Icons.male_rounded, Sex.male)),
                        const SizedBox(width: 10),
                        Expanded(child: _sexPill(colors, 'Female', Icons.female_rounded, Sex.female)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Activity level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ActivityLevel.values.map((a) {
                        final selected = _activity == a;
                        return GestureDetector(
                          onTap: () => setState(() => _activity = a),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected ? colors.primary : colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.18)),
                            ),
                            child: Text(
                              a.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : colors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _diabeticToggle(colors),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sexPill(AppPalette colors, String label, IconData icon, Sex value) {
    final selected = _sex == value;
    return GestureDetector(
      onTap: () => setState(() => _sex = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.primary : colors.textSecondary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : colors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _diabeticToggle(AppPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diabetic / pre-diabetic',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text('Adjusts how we estimate your sugar response',
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _isDiabetic,
            activeColor: colors.primary,
            onChanged: (v) => setState(() => _isDiabetic = v),
          ),
        ],
      ),
    );
  }

  Widget _field(AppPalette colors, String label, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      inputFormatters: type == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        floatingLabelStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SettingItem(this.icon, this.label, this.color, {this.onTap});
}
