import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the single daily practice-reminder notification.
/// Wired in KvlApp — reschedules automatically whenever the user changes
/// reminder time or notification sound in the Profile settings tab.
class NotificationScheduler {
  static const _reminderId = 1001;
  static const _channelId = 'kvl_reminder';
  static const _channelName = 'Practice Reminders';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> _ensureInit() async {
    if (_initialised) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Daily reminder to complete your practice',
            importance: Importance.high,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
  }

  /// Schedule (or reschedule) a repeating reminder every minute.
  /// Pass [sound] = 'none' to cancel the reminder entirely.
  Future<void> reschedule(TimeOfDay time, {String sound = 'bell'}) async {
    await _ensureInit();
    await _plugin.cancel(id: _reminderId);
    if (sound == 'none') return;

    final androidSound = sound == 'none'
        ? null
        : RawResourceAndroidNotificationSound(sound.toLowerCase());

    await _plugin.periodicallyShow(
      id: _reminderId,
      title: 'Time to practice 🙏',
      body: 'Your daily mantra session is waiting for you.',
      repeatInterval: RepeatInterval.everyMinute,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Daily reminder to complete your practice',
          importance: Importance.high,
          priority: Priority.high,
          sound: androidSound,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel() => _plugin.cancel(id: _reminderId);
}
