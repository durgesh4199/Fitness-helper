import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/providers/health_provider.dart';

void main() {
  group('HealthProvider.personalizedStepTarget (pure, no Health Connect needed)', () {
    test('is roughly 10% above the trailing average', () {
      final target = HealthProvider.personalizedStepTarget(5800);
      expect(target, greaterThan(5800));
      expect(target, lessThan(7000));
    });

    test('rounds to a friendly multiple of 100', () {
      final target = HealthProvider.personalizedStepTarget(6023);
      expect(target % 100, 0);
    });

    test('never drops below the floor for a very low average', () {
      expect(HealthProvider.personalizedStepTarget(200), 3000);
    });

    test('never exceeds the ceiling for a very high average', () {
      expect(HealthProvider.personalizedStepTarget(50000), 20000);
    });
  });
}
