import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/bioavailability.dart';
import 'package:fitness_tracker/widgets/improve_meal_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

BioavailabilityEstimate _estimate(String nutrient, List<String> recommendations) {
  return BioavailabilityEstimate(
    nutrient: nutrient,
    intake: 1,
    level: BioavailabilityLevel.moderate,
    confidence: EvidenceConfidence.medium,
    recommendations: recommendations,
    explanation: 'x',
  );
}

void main() {
  group('ImproveMealBanner', () {
    testWidgets('renders nothing when no estimate has a recommendation', (tester) async {
      await tester.pumpWidget(_wrap(ImproveMealBanner(estimates: [
        _estimate('Iron', const []),
        _estimate('Zinc', const []),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Improve this meal'), findsNothing);
    });

    testWidgets('shows the first recommendation, tagged with its nutrient', (tester) async {
      await tester.pumpWidget(_wrap(ImproveMealBanner(estimates: [
        _estimate('Iron', const ['Add a vitamin-C-rich food.']),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Improve this meal'), findsOneWidget);
      expect(find.textContaining('Iron: Add a vitamin-C-rich food.'), findsOneWidget);
    });

    testWidgets('multiple recommendations across nutrients: first shown, rest behind a toggle', (tester) async {
      await tester.pumpWidget(_wrap(ImproveMealBanner(estimates: [
        _estimate('Iron', const ['Add a vitamin-C-rich food.']),
        _estimate('Zinc', const ['Vary your protein sources.']),
      ])));
      await tester.pumpAndSettle();

      expect(find.textContaining('Iron: Add a vitamin-C-rich food.'), findsOneWidget);
      expect(find.text('+1 more tip'), findsOneWidget);
      expect(find.textContaining('Zinc: Vary your protein sources.'), findsNothing);

      await tester.tap(find.text('+1 more tip'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Zinc: Vary your protein sources.'), findsOneWidget);
      expect(find.text('Show fewer tips'), findsOneWidget);
    });

    testWidgets('an identical recommendation string from two nutrients is not duplicated', (tester) async {
      await tester.pumpWidget(_wrap(ImproveMealBanner(estimates: [
        _estimate('Iron', const ['Same tip.']),
        _estimate('Iron', const ['Same tip.']),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Improve this meal'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing); // no "+N more" -- only one unique tip
    });
  });
}
