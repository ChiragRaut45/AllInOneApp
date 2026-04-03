import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification clicked: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: (response) {
        print('Background notification clicked: ${response.payload}');
      },
    );

    /// ✅ Ensure permissions are requested
    await requestNotificationPermission();
  }

  /// 🔔 REQUEST PERMISSION (IMPORTANT)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (!status.isGranted) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    return true;
  }

  /// 🔔 SCHEDULE NOTIFICATION
  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final granted = await requestNotificationPermission();

    if (!granted) {
      print('Notification permission not granted. Skipping schedule.');
      return false;
    }

    var scheduleTime = scheduledDate;
    if (scheduleTime.isBefore(DateTime.now())) {
      scheduleTime = DateTime.now().add(const Duration(seconds: 30));
      print('Requested time is past; scheduling 30 seconds from now.');
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel',
            'Todo Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e) {
      print('Failed to schedule exact notification: $e');

      // Fallback: show immediate notification when exact alarms are unavailable.
      if (e.toString().contains('exact_alarms_not_permitted')) {
        await showNotification(id: id, title: title, body: body);
        return true;
      }

      return false;
    }
  }

  /// 🔔 IMMEDIATE NOTIFICATION (debug / fallback)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_channel',
          'Todo Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'todo_$id',
    );
  }
}
