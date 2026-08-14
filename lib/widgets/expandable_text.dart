import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standing UI convention for this app: any block of text that might run
/// long should collapse to [maxLines] with a tap-to-expand affordance,
/// rather than either dumping the full text into a compact card/list or
/// silently truncating it with no way to see the rest.
///
/// Collapses again on a second tap ("Show less"), so it doesn't permanently
/// take over the layout once opened.
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;

  const ExpandableText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.textAlign = TextAlign.start,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = widget.style ?? TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.4);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure whether the full text actually overflows maxLines at this
        // width — if it doesn't, there's nothing to expand and no toggle
        // should show up.
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
          textAlign: widget.textAlign,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              textAlign: widget.textAlign,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
