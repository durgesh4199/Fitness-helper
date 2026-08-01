import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitness_tracker/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  });

  testWidgets('App loads home screen with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const FitnessTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.fitness_center_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pick a category and get moving'), findsOneWidget);
  });

  testWidgets('New user sees onboarding flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FitnessTrackerApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('What should we call you?'), findsOneWidget);
  });
}
