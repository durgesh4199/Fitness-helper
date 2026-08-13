import 'health_data_source.dart';

/// An optional historical body-measurement entry. Every field is nullable —
/// the spec is explicit that waist circumference is the one measurement
/// worth prioritizing; the rest are here for completeness but not required.
class BodyMeasurementLog {
  final int? id;
  final DateTime dateTime;
  final double? waistCm;
  final double? neckCm;
  final double? chestCm;
  final double? armsCm;
  final double? thighsCm;
  final double? hipsCm;
  final HealthDataSource source;
  final String? notes;

  const BodyMeasurementLog({
    this.id,
    required this.dateTime,
    this.waistCm,
    this.neckCm,
    this.chestCm,
    this.armsCm,
    this.thighsCm,
    this.hipsCm,
    this.source = HealthDataSource.userEntered,
    this.notes,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'date_time': dateTime.toIso8601String(),
        'waist_cm': waistCm,
        'neck_cm': neckCm,
        'chest_cm': chestCm,
        'arms_cm': armsCm,
        'thighs_cm': thighsCm,
        'hips_cm': hipsCm,
        'source': source.name,
        'notes': notes,
      };

  factory BodyMeasurementLog.fromMap(Map<String, Object?> m) => BodyMeasurementLog(
        id: m['id'] as int?,
        dateTime: DateTime.parse(m['date_time'] as String),
        waistCm: (m['waist_cm'] as num?)?.toDouble(),
        neckCm: (m['neck_cm'] as num?)?.toDouble(),
        chestCm: (m['chest_cm'] as num?)?.toDouble(),
        armsCm: (m['arms_cm'] as num?)?.toDouble(),
        thighsCm: (m['thighs_cm'] as num?)?.toDouble(),
        hipsCm: (m['hips_cm'] as num?)?.toDouble(),
        source: HealthDataSource.values.firstWhere(
          (s) => s.name == m['source'],
          orElse: () => HealthDataSource.userEntered,
        ),
        notes: m['notes'] as String?,
      );

  BodyMeasurementLog copyWith({int? id}) => BodyMeasurementLog(
        id: id ?? this.id,
        dateTime: dateTime,
        waistCm: waistCm,
        neckCm: neckCm,
        chestCm: chestCm,
        armsCm: armsCm,
        thighsCm: thighsCm,
        hipsCm: hipsCm,
        source: source,
        notes: notes,
      );
}
