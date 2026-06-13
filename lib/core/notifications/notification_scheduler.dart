import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    // Initialize timezone database then pick local location by UTC offset.
    tz.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset;
    tz.Location? local;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.zones.isNotEmpty &&
          loc.zones.last.offset.inSeconds == offset.inSeconds) {
        local = loc;
        if (loc.name == 'Asia/Kolkata') break; // prefer IST for Indian users
      }
    }
    tz.setLocalLocation(local ?? tz.UTC);

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          // Show banner even when the app is in the foreground.
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
        ),
      ),
      onDidReceiveNotificationResponse: _onForegroundNotification,
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
            playSound: true,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
  }

  /// Schedule a daily reminder at [time]. Pass [sound] = 'none' to cancel.
  Future<void> reschedule(TimeOfDay time, {String sound = 'bell'}) async {
    await _ensureInit();
    await _plugin.cancel(id: _reminderId);
    if (sound == 'none') return;

    final androidSound = RawResourceAndroidNotificationSound(sound.toLowerCase());

    // Compute the next occurrence of [time] in local timezone.
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    // Convert to TZDateTime using UTC (offset already baked into local DateTime).
    final tzNext = tz.TZDateTime.from(next.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: 'Time to practice \u{1F64F}',
      body: 'Your daily mantra session is waiting for you.',
      scheduledDate: tzNext,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Daily reminder to complete your practice',
          importance: Importance.high,
          priority: Priority.high,
          sound: androidSound,
          playSound: true,
          enableVibration: true,
          // Show heads-up even when app is in foreground on Android.
          fullScreenIntent: false,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: sound != 'none' ? '$sound.aiff' : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() => _plugin.cancel(id: _reminderId);
}

void _onForegroundNotification(NotificationResponse response) {
  // Tapping the notification brings the app to the foreground naturally.
}

@pragma('vm:entry-point')
void _onBackgroundNotification(NotificationResponse response) {}
