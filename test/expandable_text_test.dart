import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/widgets/expandable_text.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 200, child: child)),
    );

void main() {
  group('ExpandableText', () {
    testWidgets('short text shows no "Show more" toggle', (tester) async {
      await tester.pumpWidget(_wrap(const ExpandableText('Short.', maxLines: 2)));
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsNothing);
    });

    testWidgets('long text shows a "Show more" toggle that expands and collapses on tap', (tester) async {
      const longText =
          'This is a deliberately long piece of explanatory text meant to wrap across '
          'more than two lines when constrained to a narrow width, so the expand '
          'affordance should appear beneath it for the user to tap.';
      await tester.pumpWidget(_wrap(const ExpandableText(longText, maxLines: 2)));
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsOneWidget);
      expect(find.text('Show less'), findsNothing);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);

      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsOneWidget);
    });
  });
}
