import 'health_data_source.dart';

/// One day's synced activity/sleep snapshot — separate from
/// [HealthProvider]'s live "today" cache, this is what accumulates real
/// history so trend and pattern features have more than a single day to
/// work with. One row per calendar date (upserted on each sync).
class DailyHealthLog {
  final int? id;
  final DateTime date; // date-only (time component ignored)
  final int? steps;
  final int? sleepMinutes;
  final HealthDataSource source;

  const DailyHealthLog({
    this.id,
    required this.date,
    this.steps,
    this.sleepMinutes,
    this.source = HealthDataSource.healthConnect,
  });

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Stable per-day key, e.g. "2026-08-13".
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => {
        'id': id,
        'date': dateKey,
        'steps': steps,
        'sleep_minutes': sleepMinutes,
        'source': source.name,
      };

  factory DailyHealthLog.fromMap(Map<String, Object?> m) => DailyHealthLog(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        steps: (m['steps'] as num?)?.toInt(),
        sleepMinutes: (m['sleep_minutes'] as num?)?.toInt(),
        source: HealthDataSource.values.firstWhere(
          (s) => s.name == m['source'],
          orElse: () => HealthDataSource.healthConnect,
        ),
      );
}
