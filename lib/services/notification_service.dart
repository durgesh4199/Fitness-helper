import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _waterChannelId = 'water_reminders';
  static const _waterNotificationIdBase = 100;
  static const _waterWindowStartHour = 8;
  static const _waterWindowEndHour = 22;

  static const _movementChannelId = 'movement_reminders';
  static const _movementNotificationIdBase = 200;
  static const _movementWindowStartHour = 9;
  static const _movementWindowEndHour = 21;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // This app targets Indian users; hardcoding avoids pulling in a separate
    // platform-timezone-detection plugin just for this.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _waterChannelId,
        'Water reminders',
        description: 'Reminders to log your water intake',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _movementChannelId,
        'Movement reminders',
        description: 'Reminders to take a short movement break',
        importance: Importance.defaultImportance,
      ));
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> cancelWaterReminders() async {
    for (var i = 0; i < 24; i++) {
      await _plugin.cancel(id: _waterNotificationIdBase + i);
    }
  }

  Future<void> scheduleWaterReminders(int intervalHours) async {
    await cancelWaterReminders();
    if (intervalHours <= 0) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _waterChannelId,
        'Water reminders',
        channelDescription: 'Reminders to log your water intake',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    var id = _waterNotificationIdBase;
    for (var hour = _waterWindowStartHour; hour <= _waterWindowEndHour; hour += intervalHours) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: id++,
        title: 'Time to hydrate 💧',
        body: 'Log a glass of water in Fitness Tracker to stay on track.',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // Movement/sedentary-break reminders. Note: these are plain scheduled
  // reminders on a fixed interval, not real inactivity detection — the app
  // has no way to sense whether you've actually been sitting still (that
  // would need a continuously-running background activity-recognition
  // service, well beyond a locally-scheduled notification). Framed as a
  // periodic nudge, matching the spec's "make notifications configurable"
  // guidance, not as "you've been inactive for N minutes".
  Future<void> cancelMovementReminders() async {
    for (var i = 0; i < 24; i++) {
      await _plugin.cancel(id: _movementNotificationIdBase + i);
    }
  }

  Future<void> scheduleMovementReminders(int intervalHours) async {
    await cancelMovementReminders();
    if (intervalHours <= 0) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _movementChannelId,
        'Movement reminders',
        channelDescription: 'Reminders to take a short movement break',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    var id = _movementNotificationIdBase;
    for (var hour = _movementWindowStartHour; hour <= _movementWindowEndHour; hour += intervalHours) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: id++,
        title: 'Stretch your legs 🚶',
        body: 'A short walk or stretch break — good for a sedentary stretch of the day.',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
