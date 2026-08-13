import 'health_data_source.dart';

/// A single water-intake entry. The running daily total shown around the app
/// (`UserProvider.waterIntakeMl`) stays the fast path for "how much today",
/// while these rows give history (weekly averages, daily breakdown) without
/// changing that existing behavior.
class WaterLog {
  final int? id;
  final int amountMl;
  final DateTime dateTime;
  final HealthDataSource source;

  const WaterLog({
    this.id,
    required this.amountMl,
    required this.dateTime,
    this.source = HealthDataSource.userEntered,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'amount_ml': amountMl,
        'date_time': dateTime.toIso8601String(),
        'source': source.name,
      };

  factory WaterLog.fromMap(Map<String, Object?> m) => WaterLog(
        id: m['id'] as int?,
        amountMl: (m['amount_ml'] as num).toInt(),
        dateTime: DateTime.parse(m['date_time'] as String),
        source: HealthDataSource.values.firstWhere(
          (s) => s.name == m['source'],
          orElse: () => HealthDataSource.userEntered,
        ),
      );

  WaterLog copyWith({int? id}) => WaterLog(
        id: id ?? this.id,
        amountMl: amountMl,
        dateTime: dateTime,
        source: source,
      );
}
