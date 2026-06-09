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

    final scheduledDate = now.add(Duration(minutes: minutes));

    print("NOW: $now");
    print("SCHEDULED: $scheduledDate");

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

      // 🔥 FIX 1: use correct scheduling mode for reliability
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      // optional but safe default
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
