# 🔔 FrostHub Notification System Test Checklist

This checklist ensures the local notification system (class reminders, announcement alerts via socket) is working as expected — even when the app is **terminated** or **rebooted**.

---

## ✅ Basic Functional Tests

| Test | Steps | Expected Outcome |
|------|-------|------------------|
| **Test Reminder Trigger** | Tap "Test Class Reminder" FAB button on dashboard. | Notification appears after ~1 minute. |
| **Real Class Reminder** | Schedule a real class in today’s timetable ~2–5 min ahead. | Notified ~10 min and 5 min before class. |
| **Manual App Termination** | Swipe app away from recent apps. | Still receive class notifications. |
| **Reboot Device** | Schedule a class reminder, then reboot device. | Reminder still fires on time. |

---

## 📱 Android 13+ Compatibility

| Test | Steps | Expected Outcome |
|------|-------|------------------|
| **POST_NOTIFICATIONS permission** | Run app on Android 13+ (API 33+). | Prompt appears requesting notification permission. |
| **Grant/Deny test** | Try both accepting and denying permission. | Notifications behave as expected (work only if granted). |

---

## 🧪 Advanced Tests

| Test | Steps | Expected Outcome |
|------|-------|------------------|
| **Socket Announcement Push** | Trigger an announcement on backend while app is backgrounded/terminated. | Local notification with title/message received. |
| **Deep Link Handling** | Open a link like `https://frosthub-6ca1c.web.app`. | App launches and handles route gracefully. |
| **Exact Alarm Scheduling** | Schedule classes around current time (e.g. 1 min later). | Notification appears precisely. |

---

## 🛠️ Debugging Tips

- ✅ Check `adb logcat` for logs like:  
  `🔔 Scheduled notification for: ...` or `🔌 Connected to socket`
- ✅ Verify that `NotificationService.initialize()` and `requestPermissions()` are called in `main.dart`
- ✅ `BOOT_COMPLETED` and exact alarm permission are declared in `AndroidManifest.xml`

---

> **Author:** Chloe & Frost ✨  
> **Last Updated:** August 2025  
