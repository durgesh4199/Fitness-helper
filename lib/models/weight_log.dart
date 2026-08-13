import 'health_data_source.dart';

/// A single historical weight (and optional body-fat) measurement — distinct
/// from [UserProvider.weightKg], which is just the current value used for
/// calculations. Keeping a history lets the app show trends instead of
/// reacting to a single day's number.
class WeightLog {
  final int? id;
  final double weight; // kg
  final double? bodyFat; // % (optional)
  final DateTime dateTime;
  final HealthDataSource source;
  final String? notes;

  const WeightLog({
    this.id,
    required this.weight,
    this.bodyFat,
    required this.dateTime,
    this.source = HealthDataSource.userEntered,
    this.notes,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'weight': weight,
        'body_fat': bodyFat,
        'date_time': dateTime.toIso8601String(),
        'source': source.name,
        'notes': notes,
      };

  factory WeightLog.fromMap(Map<String, Object?> m) => WeightLog(
        id: m['id'] as int?,
        weight: (m['weight'] as num).toDouble(),
        bodyFat: (m['body_fat'] as num?)?.toDouble(),
        dateTime: DateTime.parse(m['date_time'] as String),
        source: HealthDataSource.values.firstWhere(
          (s) => s.name == m['source'],
          orElse: () => HealthDataSource.userEntered,
        ),
        notes: m['notes'] as String?,
      );

  WeightLog copyWith({int? id}) => WeightLog(
        id: id ?? this.id,
        weight: weight,
        bodyFat: bodyFat,
        dateTime: dateTime,
        source: source,
        notes: notes,
      );
}
