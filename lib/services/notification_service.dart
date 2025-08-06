import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🛠️ Initialize all notification channels and plugin
  static Future<void> initialize() async {
    await _createAndroidChannel(
      id: 'default_channel',
      name: 'Default Channel',
      description: 'This channel is used for important notifications.',
    );

    await _createAndroidChannel(
      id: 'announcement_channel',
      name: 'Announcements',
      description: 'Notifications for announcements.',
    );

    await _createAndroidChannel(
      id: 'class_channel',
      name: 'Class Reminders',
      description: 'Reminders for upcoming classes.',
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  // 🧱 Android channel creation helper
  static Future<void> _createAndroidChannel({
    required String id,
    required String name,
    required String description,
  }) async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          name,
          description: description,
          importance: Importance.high,
        ),
      );
    }
  }

  static Future<void> requestPermissions() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // ✅ Android 13+: POST_NOTIFICATIONS permission
    await androidPlugin?.requestPermission();

    // 🍎 iOS permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // ✅ Android 13+: SCHEDULE_EXACT_ALARM permission
    if (Platform.isAndroid) {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (!alarmStatus.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        if (!result.isGranted) {
          print('⚠️ User denied SCHEDULE_EXACT_ALARM permission');
        }
      }

      // 🔋 Optional: Ask to ignore battery optimizations
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  // 📅 Schedule class reminders dynamically
  static Future<void> scheduleClassReminders(
    List<Map<String, dynamic>> classes, {
    bool repeatDaily = false,
  }) async {
    for (int i = 0; i < classes.length; i++) {
      final classData = classes[i];

      final rawStartTime = classData['startTime'];
      final subject = classData['subject']?.toString() ?? 'Class';

      // ✅ Skip if startTime is null or invalid
      if (rawStartTime == null || rawStartTime.toString().isEmpty) {
        log('⚠️ Skipping class with missing startTime: $classData');
        continue;
      }

      DateTime? startTime;
      try {
        startTime = DateTime.parse(rawStartTime);
      } catch (e) {
        log('❌ Invalid startTime format: $rawStartTime');
        continue;
      }

      final reminder10Min = startTime.subtract(const Duration(minutes: 10));
      final reminder5Min = startTime.subtract(const Duration(minutes: 5));

      if (reminder10Min.isAfter(DateTime.now())) {
        await scheduleClassNotification(
          id: i * 10 + 1,
          title: 'Upcoming Class',
          body:
              '$subject starts at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
          scheduledTime: reminder10Min,
          repeatDaily: repeatDaily,
        );
        log('🔔 Scheduled 10-minute reminder for $subject at $reminder10Min');
      }

      if (reminder5Min.isAfter(DateTime.now())) {
        await scheduleClassNotification(
          id: i * 10 + 2,
          title: 'Get Ready!',
          body:
              '$subject starts at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
          scheduledTime: reminder5Min,
          repeatDaily: repeatDaily,
        );
        log('🔔 Scheduled 5-minute reminder for $subject at $reminder5Min');
      }
    }
  }

  // 🔔 Show instant announcement notification
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

  // 🕒 Schedule single class reminder (optionally repeat daily)
  static Future<void> scheduleClassNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatDaily = false,
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
      matchDateTimeComponents:
          repeatDaily ? DateTimeComponents.dayOfWeekAndTime : null,
    );
  }

  // ✅ Test notification
  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test message!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ❌ Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    log("🧹 All notifications cancelled");
  }
}
