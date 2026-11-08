import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class SmartNotificationService {
  SmartNotificationService._();

  static final instance = SmartNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    timezone_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
    } catch (_) {
      timezone.setLocalLocation(timezone.UTC);
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<void> scheduleFocusTimerNotification({
    required String taskName,
    required Duration duration,
  }) async {
    if (kIsWeb) return;
    await initialize();
    await _requestPermission();

    final targetTime = DateTime.now().add(duration);
    await _plugin.cancel(id: 999999);
    await _plugin.zonedSchedule(
      id: 999999,
      title: '🎉 Focus Session Completed!',
      body: 'Great job working on "$taskName"! Take your 10-minute break.',
      scheduledDate: timezone.TZDateTime.from(targetTime, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'orbit_focus_timer',
          'Focus Timer Alerts',
          channelDescription: 'Alerts when your Pomodoro focus session finishes',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'focus_timer_done',
    );
  }

  Future<void> cancelFocusTimerNotification() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: 999999);
  }

  Future<void> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

}
