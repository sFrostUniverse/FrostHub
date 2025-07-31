import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'dart:developer'; // for debug logging
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize time zones (required for zonedSchedule)
    tzData.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 🔑 Firebase Messaging Setup
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🔐 Get the device token and print it
    final token = await messaging.getToken();
    print('🔑 FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _notificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_foreground_channel',
              'FCM Foreground',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Handle app open from terminated state via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 App opened from notification: ${message.notification?.title}');
      // Optional: Navigate to a specific screen here
    });
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
