import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer'; // for debug logging

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel', // MUST match manifest
      'Default Channel',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize plugin
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  static Future<void> requestPermissions() async {
    // For Android 13+ and iOS: request notification permission
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> showAnnouncementNotification({
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'announcement_channel',
          'Announcements',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleClassReminders(
      List<Map<String, dynamic>> classes) async {
    for (int i = 0; i < classes.length; i++) {
      final classData = classes[i];

      final startTime = DateTime.parse(classData['startTime']); // must be ISO
      final reminder10Min = startTime.subtract(const Duration(minutes: 10));
      final reminder5Min = startTime.subtract(const Duration(minutes: 5));

      if (reminder10Min.isAfter(DateTime.now())) {
        await scheduleClassNotification(
          id: i * 10 + 1,
          title: 'Upcoming Class',
          body:
              '${classData['subject']} starts at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
          scheduledTime: reminder10Min,
        );
        log('🔔 Scheduled 10-minute reminder for ${classData['subject']} at $reminder10Min');
      }

      if (reminder5Min.isAfter(DateTime.now())) {
        await scheduleClassNotification(
          id: i * 10 + 2,
          title: 'Get Ready!',
          body:
              '${classData['subject']} starts at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
          scheduledTime: reminder5Min,
        );
        log('🔔 Scheduled 5-minute reminder for ${classData['subject']} at $reminder5Min');
      }
    }
  }

  static Future<void> scheduleClassNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTz,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_channel',
          'Class Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Optional
    );
  }

  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test message!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_id',
          'Test Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
