import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rate of Perceived Exertion picker: "How hard was this workout? 1 — 10".
/// Purely subjective and optional — never required, never medical.
class RpeSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const RpeSelector({super.key, required this.value, required this.onChanged});

  Color _colorFor(AppPalette colors, int n) {
    if (n <= 3) return AppBrand.fiber;
    if (n <= 6) return colors.primary;
    if (n <= 8) return AppBrand.accentOrange;
    return AppBrand.accentPink;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('How hard was this workout?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
            const Spacer(),
            Text('Optional', style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var n = 1; n <= 10; n++)
              GestureDetector(
                onTap: () => onChanged(value == n ? null : n),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == n ? _colorFor(colors, n) : colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: value == n ? Colors.transparent : colors.cardBorder),
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value == n ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 6),
          Text(_labelFor(value!), style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
        ],
      ],
    );
  }

  String _labelFor(int n) {
    if (n <= 2) return 'Very easy';
    if (n <= 4) return 'Easy';
    if (n <= 6) return 'Moderate';
    if (n <= 8) return 'Hard';
    return 'Max effort';
  }
}
