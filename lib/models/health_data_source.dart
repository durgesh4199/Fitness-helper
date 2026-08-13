/// Where a piece of health/fitness data came from — lets the UI distinguish
/// a real measurement from something the app worked out on its own, instead
/// of presenting every number with the same authority.
///
/// - [userEntered]: typed in directly by the user (e.g. a weight entry).
/// - [healthConnect]: read from Android Health Connect (e.g. steps synced
///   from a watch via its companion app).
/// - [device]: read directly from a connected device/sensor (reserved for
///   future direct-device integrations; not currently used).
/// - [calculated]: a deterministic formula applied to measured inputs (e.g.
///   BMI from height/weight, TDEE from BMR).
/// - [estimated]: a best-effort approximation where some inputs are unknown
///   or assumed (e.g. calories burned when a device doesn't report it).
/// - [heuristic]: a rule-of-thumb model, not a medical calculation (e.g. the
///   meal-impact estimate).
enum HealthDataSource {
  userEntered,
  healthConnect,
  device,
  calculated,
  estimated,
  heuristic,
}

extension HealthDataSourceX on HealthDataSource {
  /// Short label suitable for a small "via ..." caption in the UI.
  String get label => switch (this) {
        HealthDataSource.userEntered => 'You entered this',
        HealthDataSource.healthConnect => 'Health Connect',
        HealthDataSource.device => 'Device',
        HealthDataSource.calculated => 'Calculated',
        HealthDataSource.estimated => 'Estimated',
        HealthDataSource.heuristic => 'Estimate, not a measurement',
      };

  /// Whether this value is a real measurement (typed by the user or read
  /// from a device/Health Connect) as opposed to something the app derived.
  bool get isMeasured =>
      this == HealthDataSource.userEntered ||
      this == HealthDataSource.healthConnect ||
      this == HealthDataSource.device;
}
