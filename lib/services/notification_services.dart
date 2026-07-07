import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hydration_app/services/water_service.dart';
import 'package:hydration_app/services/water_sync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:shared_preferences/shared_preferences.dart';


@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == 'drink_water') {

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    final supabase = SupabaseClient(
      'https://gysjshfvkbocjmhfgawp.supabase.co/',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5c2pzaGZ2a2JvY2ptaGZnYXdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4ODQxMjUsImV4cCI6MjA5NTQ2MDEyNX0.VgGcuinb0nMQlR8gp-qskzIxSmuUB-CnmX4TvXcJq_Q'
    );

    await supabase.from('water_logs').insert({
      'user_id': userId,
      'amount': 250,
    });

    WaterSync.notify();
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );
    debugPrint(tz.local.name);

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
      ),
      onDidReceiveNotificationResponse: (response) async {
        debugPrint('ACTION PRESSED -> ${response.actionId}');

        if (response.actionId == 'drink_water') {
          final userId = Supabase.instance.client.auth.currentUser?.id;

          if (userId == null) return;

          await WaterService.addWater(250, userId);

          WaterSync.notify();

          debugPrint('250ml added');
        }

        if (response.actionId == 'dismiss') return;
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final canSchedule = await android?.canScheduleExactNotifications();
    debugPrint("Can schedule exact: $canSchedule");

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'hydration_channel',
        'Hydration Reminders',
        description: 'Water reminders',
        importance: Importance.max,
      ),
    );

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
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

          actions: [
            AndroidNotificationAction(
                'drink_water',
                'Drink water',
            ),
            AndroidNotificationAction(
                'dismiss',
                'Dismiss',
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> scheduleDailyReminders({
    required TimeOfDay wakeTime,
    required TimeOfDay sleepTime,
    required int intervalMinutes,
  }) async {
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    var reminder = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      wakeTime.hour,
      wakeTime.minute,
    );

    final end = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      sleepTime.hour,
      sleepTime.minute,
    );

    int id = 1;

    while (reminder.isBefore(end) || reminder.isAtSameMomentAs(end)) {

      if (reminder.isAfter(now)) {
        await _plugin.zonedSchedule(
          id,
          'Hydration Coach 💧',
          'Time to drink water',
          reminder,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'hydration_channel',
              'Hydration Reminders',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              actions: [
                AndroidNotificationAction(
                  'drink_water',
                  'Drink water',
                ),
                AndroidNotificationAction(
                  'dismiss',
                  'Dismiss',
                ),
              ],
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        id++;
      }

      reminder = reminder.add(
        Duration(minutes: intervalMinutes),
      );
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required int minutes,
  }) async {
    final now = tz.TZDateTime.now(tz.local);


    final scheduledDate = now.add(
      Duration(minutes: minutes),
    );
    try {
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

            actions: [
              AndroidNotificationAction(
                'drink_water',
                'Drink water',
              ),
              AndroidNotificationAction(
                'dismiss',
                'Dismiss',
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("Now: $now");
      debugPrint("Scheduling for: $scheduledDate");
      final pending = await _plugin.pendingNotificationRequests();

      debugPrint("Pending notifications:");
      for (final p in pending) {
        debugPrint("${p.id} ${p.title}");
      }

    } catch (e, stack) {
      debugPrint("Schedule error:");
      debugPrint(e.toString());
      debugPrint(stack.toString());
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
