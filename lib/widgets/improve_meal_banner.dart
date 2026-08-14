import 'package:flutter/material.dart';
import '../models/bioavailability.dart';
import '../theme/app_theme.dart';
import 'expandable_text.dart';

/// A single, consolidated "what would help this meal" banner, built from
/// every nutrient's [BioavailabilityEstimate.recommendations] for one meal.
/// Complements — doesn't replace — the per-nutrient BioavailabilityCards
/// shown alongside it: this is the "at a glance, one place" layer; the cards
/// underneath are where the full per-nutrient detail and context live.
///
/// Renders nothing when no estimate has a recommendation — most meals won't.
class ImproveMealBanner extends StatefulWidget {
  final List<BioavailabilityEstimate> estimates;

  const ImproveMealBanner({super.key, required this.estimates});

  @override
  State<ImproveMealBanner> createState() => _ImproveMealBannerState();
}

class _ImproveMealBannerState extends State<ImproveMealBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Flatten in the order [estimates] is already built (Iron, Protein,
    // Zinc, Calcium, fat-soluble vitamins — see diet_screen.dart), tagging
    // each tip with its nutrient so a reader can tell which one it's about
    // once more than one shows up.
    final tips = <String>[];
    for (final e in widget.estimates) {
      for (final r in e.recommendations) {
        final tagged = '${e.nutrient}: $r';
        if (!tips.contains(tagged)) tips.add(tagged);
      }
    }

    if (tips.isEmpty) return const SizedBox.shrink();

    final extra = tips.skip(1).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'Improve this meal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colors.primary, letterSpacing: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ExpandableText(
            tips.first,
            maxLines: 3,
            style: TextStyle(fontSize: 12.5, color: colors.textPrimary, height: 1.35),
          ),
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show fewer tips' : '+${extra.length} more tip${extra.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: extra
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ExpandableText(
                              t,
                              maxLines: 3,
                              style: TextStyle(fontSize: 12.5, color: colors.textPrimary, height: 1.35),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
