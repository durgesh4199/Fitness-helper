import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/recovery_signal.dart';
import 'package:fitness_tracker/models/workout_log.dart';

WorkoutLog _log({int? rpe}) {
  return WorkoutLog(title: 'Session', category: 'Strength', minutes: 45, calories: 300, dateTime: DateTime(2026, 1, 1), rpe: rpe);
}

void main() {
  group('RecoveryAdvisor.evaluate', () {
    test('says nothing below the minimum streak, even with high recent effort', () {
      final logs = [_log(rpe: 9), _log(rpe: 9), _log(rpe: 9)];
      final signal = RecoveryAdvisor.evaluate(logs, streakDays: RecoveryAdvisor.considerRestStreakDays - 1);
      expect(signal, isNull);
    });

    test('says nothing on a long streak if nothing recent has an rpe logged', () {
      final logs = [_log(), _log(), _log()];
      final signal = RecoveryAdvisor.evaluate(logs, streakDays: 10);
      expect(signal, isNull);
    });

    test('says nothing on a long streak if recent effort has been low', () {
      final logs = [_log(rpe: 4), _log(rpe: 5), _log(rpe: 4)];
      final signal = RecoveryAdvisor.evaluate(logs, streakDays: 10);
      expect(signal, isNull);
    });

    test('suggests a check-in at the lower streak threshold with high effort', () {
      final logs = [_log(rpe: 8), _log(rpe: 7), _log(rpe: 8)];
      final signal = RecoveryAdvisor.evaluate(logs, streakDays: RecoveryAdvisor.considerRestStreakDays);
      expect(signal, isNotNull);
      expect(signal!.level, RecoveryLevel.considerRest);
    });

    test('recommends rest at the higher streak threshold with high effort', () {
      final logs = [_log(rpe: 8), _log(rpe: 9), _log(rpe: 8)];
      final signal = RecoveryAdvisor.evaluate(logs, streakDays: RecoveryAdvisor.restRecommendedStreakDays);
      expect(signal, isNotNull);
      expect(signal!.level, RecoveryLevel.restRecommended);
    });

    test('only considers the most recent rated sessions, not old ones', () {
      // Older-than-window sessions were tough, but the recent window is mild.
      final logs = [
        _log(rpe: 3),
        _log(rpe: 3),
        _log(rpe: 3),
        _log(rpe: 9),
        _log(rpe: 9),
      ];
      final signal = RecoveryAdvisor.evaluate(logs, streakDays: 10);
      expect(signal, isNull);
    });
  });
}
