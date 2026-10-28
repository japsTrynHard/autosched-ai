import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Wraps flutter_local_notifications for deadline reminders.
/// All methods are no-ops on web; errors are swallowed silently so the
/// rest of the app continues to function even if notifications are unavailable.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> requestPermissions() async {
    if (!_initialized) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Schedules a one-time notification [id] for a task deadline.
  /// [scheduledAt] must be in the future, otherwise the call is a no-op.
  static Future<void> scheduleDeadlineReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized || scheduledAt.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'autosched_deadlines',
            'Deadline Reminders',
            channelDescription: 'Reminds you of upcoming task deadlines',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
