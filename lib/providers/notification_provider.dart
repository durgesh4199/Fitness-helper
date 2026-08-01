import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const _keyEnabled = 'water_reminders_enabled';
  static const _keyIntervalHours = 'water_reminders_interval_hours';

  bool waterRemindersEnabled = false;
  int intervalHours = 2;
  bool permissionDenied = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    waterRemindersEnabled = prefs.getBool(_keyEnabled) ?? false;
    intervalHours = prefs.getInt(_keyIntervalHours) ?? 2;
    notifyListeners();

    if (waterRemindersEnabled) {
      await NotificationService.instance.scheduleWaterReminders(intervalHours);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        permissionDenied = true;
        waterRemindersEnabled = false;
        notifyListeners();
        return;
      }
      permissionDenied = false;
      await NotificationService.instance.scheduleWaterReminders(intervalHours);
    } else {
      await NotificationService.instance.cancelWaterReminders();
    }

    waterRemindersEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    notifyListeners();
  }

  Future<void> setIntervalHours(int hours) async {
    intervalHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIntervalHours, hours);
    notifyListeners();

    if (waterRemindersEnabled) {
      await NotificationService.instance.scheduleWaterReminders(hours);
    }
  }
}
