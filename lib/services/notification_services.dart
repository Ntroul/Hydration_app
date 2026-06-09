import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );

    print("Timezone set to: ${timezoneInfo.identifier}");

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final canSchedule =
    await android?.canScheduleExactNotifications();

    print("Can schedule exact notifications: $canSchedule");

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'hydration_channel',
        'Hydration Reminders',
        description: 'Water reminders',
        importance: Importance.max,
      ),
    );

    await android?.requestNotificationsPermission();
  }

  static Future<void> showTestNotification() async {
    await _plugin.show(
      1,
      'Hydration Coach',
      'Time to drink water 💧',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  static Future<void> scheduleReminder({
    required int id,
    required int minutes,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    final scheduledDate = now.add(
      Duration(minutes: minutes),
    );
    print("Device clock: ${DateTime.now()}");
    print("NOW: $now");
    print("SCHEDULED: $scheduledDate");

    try {
      print("Before zonedSchedule");

      await _plugin.zonedSchedule(
        id,
        'Hydration Coach 💧',
        'Time to drink water',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Hydration Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print("After zonedSchedule");

      final pending =
      await _plugin.pendingNotificationRequests();

      print("Pending notifications: ${pending.length}");
    } catch (e) {
      print("Schedule error: $e");
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
