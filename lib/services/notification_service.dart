import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/models/task_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _askedExactAlarm = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _android;
      if (android != null) {
        final enabled = await android.areNotificationsEnabled() ?? false;
        if (enabled) return true;
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _ios;
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
    return false;
  }

  Future<bool> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    bool askExactAlarm = false,
  }) async {
    if (!_ready || !when.isAfter(DateTime.now())) return false;

    try {
      var mode = AndroidScheduleMode.inexactAllowWhileIdle;
      final android = _android;
      if (android != null) {
        var canExact = await android.canScheduleExactNotifications() ?? false;
        if (!canExact && askExactAlarm && !_askedExactAlarm) {
          _askedExactAlarm = true;
          await android.requestExactAlarmsPermission();
          canExact = await android.canScheduleExactNotifications() ?? false;
        }
        if (canExact) mode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task reminders',
          channelDescription: 'Reminders for your tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.UTC),
        details,
        androidScheduleMode: mode,
      );
      return true;
    } catch (e) {
      debugPrint('Schedule failed: $e');
      return false;
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Cancel failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel all failed: $e');
    }
  }

  Future<void> syncReminders(List<TaskModel> tasks) async {
    for (final task in tasks) {
      if (task.reminderAt == null) continue;
      if (task.hasUpcomingReminder) {
        await scheduleReminder(
          id: task.notificationId,
          title: task.title,
          body: task.description.isEmpty
              ? 'Time to do your task!'
              : task.description,
          when: task.reminderAt!,
        );
      } else {
        await cancel(task.notificationId);
      }
    }
  }
}
