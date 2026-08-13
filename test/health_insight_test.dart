import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/daily_health_log.dart';
import 'package:fitness_tracker/models/health_insight.dart';

DailyHealthLog _log(DateTime date, {int? steps, int? sleepMinutes}) {
  return DailyHealthLog(date: date, steps: steps, sleepMinutes: sleepMinutes);
}

void main() {
  group('InsightEngine.sleepStepsCorrelation', () {
    test('says nothing with fewer than minDataPoints paired days', () {
      final logs = List.generate(
        InsightEngine.minDataPoints - 1,
        (i) => _log(DateTime(2026, 1, i + 1), steps: 5000, sleepMinutes: 400),
      );

      expect(InsightEngine.sleepStepsCorrelation(logs), isNull);
    });

    test('says nothing when days are missing either steps or sleep', () {
      // Plenty of rows, but none have both fields.
      final logs = [
        for (var i = 0; i < 20; i++) _log(DateTime(2026, 1, i + 1), steps: i.isEven ? 5000 : null, sleepMinutes: i.isOdd ? 400 : null),
      ];

      expect(InsightEngine.sleepStepsCorrelation(logs), isNull);
    });

    test('finds a pattern when higher-sleep days clearly have more steps', () {
      final logs = <DailyHealthLog>[];
      // Varying values (not two flat ties at the median) so the median
      // split lands cleanly into two non-empty groups.
      for (var i = 0; i < 10; i++) {
        logs.add(_log(DateTime(2026, 1, i + 1), steps: 4000 + i * 20, sleepMinutes: 250 + i * 10)); // lower sleep, fewer steps
      }
      for (var i = 0; i < 10; i++) {
        logs.add(_log(DateTime(2026, 2, i + 1), steps: 8500 + i * 20, sleepMinutes: 450 + i * 10)); // higher sleep, more steps
      }

      final insight = InsightEngine.sleepStepsCorrelation(logs);

      expect(insight, isNotNull);
      expect(insight!.message, contains('higher'));
    });

    test('says nothing when the difference between groups is negligible', () {
      final logs = <DailyHealthLog>[];
      for (var i = 0; i < 10; i++) {
        logs.add(_log(DateTime(2026, 1, i + 1), steps: 5000 + i, sleepMinutes: 250 + i * 10));
      }
      for (var i = 0; i < 10; i++) {
        logs.add(_log(DateTime(2026, 2, i + 1), steps: 5010 + i, sleepMinutes: 450 + i * 10)); // ~<1% step difference
      }

      expect(InsightEngine.sleepStepsCorrelation(logs), isNull);
    });
  });

  group('InsightEngine.all', () {
    test('returns an empty list rather than nulls when nothing qualifies', () {
      expect(InsightEngine.all(const []), isEmpty);
    });
  });

  group('DailyHealthLog', () {
    test('dateKey formats as zero-padded YYYY-MM-DD', () {
      final log = DailyHealthLog(date: DateTime(2026, 3, 5));
      expect(log.dateKey, '2026-03-05');
    });
  });
}
