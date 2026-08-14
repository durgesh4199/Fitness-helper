import 'package:flutter/material.dart';
import '../models/bioavailability.dart';
import '../theme/app_theme.dart';

Color _levelColor(BioavailabilityLevel level, AppPalette colors) {
  switch (level) {
    case BioavailabilityLevel.veryLow:
    case BioavailabilityLevel.low:
      return Colors.redAccent;
    case BioavailabilityLevel.moderate:
      return AppBrand.carbs; // amber
    case BioavailabilityLevel.high:
    case BioavailabilityLevel.veryHigh:
      return AppBrand.fiber; // green
    case BioavailabilityLevel.unknown:
      return colors.textSecondary;
  }
}

/// Shows one [BioavailabilityEstimate] — a level badge, enhancer/inhibitor
/// checklist, an optional recommendation, and an "About this estimate" info
/// action. Deliberately uses only category-level language ("Moderate",
/// "Potential inhibitor") — never a number that implies measured absorption.
class BioavailabilityCard extends StatelessWidget {
  final BioavailabilityEstimate estimate;

  const BioavailabilityCard({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final levelColor = _levelColor(estimate.level, colors);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${estimate.nutrient} Bioavailability',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showAboutDialog(context, estimate),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.info_outline_rounded, size: 17, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: levelColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  estimate.level.label.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: levelColor, letterSpacing: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              if (estimate.intake != null)
                Text(
                  '${estimate.intake!.toStringAsFixed(1)} mg logged',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                ),
            ],
          ),
          if (estimate.enhancers.isNotEmpty || estimate.inhibitors.isNotEmpty || estimate.contextualFactors.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...estimate.enhancers.map((e) => _FactorRow(icon: Icons.check_circle_rounded, color: AppBrand.fiber, text: e)),
            ...estimate.contextualFactors.map((e) => _FactorRow(icon: Icons.info_rounded, color: colors.accentBlue, text: e)),
            ...estimate.inhibitors.map((e) => _FactorRow(icon: Icons.warning_amber_rounded, color: AppBrand.carbs, text: 'Potential inhibitor: $e')),
          ],
          if (estimate.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estimate.recommendations.first,
                      style: TextStyle(fontSize: 12.5, color: colors.textPrimary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showAboutDialog(BuildContext context, BioavailabilityEstimate estimate) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About this estimate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This feature estimates how favorable the meal context may be for '
              '${estimate.nutrient.toLowerCase()} bioavailability, based on the foods logged.\n\n'
              'It does not measure nutrient absorption and is not a medical test.',
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text('Evidence confidence: ${estimate.confidence.label}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Got it'))],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _FactorRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: colors.textPrimary))),
        ],
      ),
    );
  }
}
