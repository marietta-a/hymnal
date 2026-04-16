import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hymnal/data/hymn_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _updateNotifId = 0;
  static const int _dailyHymnNotifId = 1;

  static const String _enabledKey = 'daily_notif_enabled';
  static const String _hourKey = 'daily_notif_hour';
  static const String _minuteKey = 'daily_notif_minute';

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Timezone setup (required for zonedSchedule)
    tz.initializeTimeZones();
    final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _requestAndroidPermission();
  }

  void _requestAndroidPermission() {
    _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── App update notification ────────────────────────────────────────────────

  void showUpdateDownloadedNotification() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'app_update_channel',
      'App Updates',
      channelDescription: 'Notifications for app updates.',
      importance: Importance.max,
      priority: Priority.high,
    );

    _plugin.show(
      _updateNotifId,
      'Update Ready to Install',
      'A new version is now available.',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ── Daily hymn notification ────────────────────────────────────────────────

  /// Schedule (or reschedule) the daily hymn notification at [time].
  /// The hymn content rotates each day based on day-of-year.
  Future<void> scheduleDailyHymnNotification(TimeOfDay time) async {
    final hymn = _hymnOfDay();
    final title = _toTitleCase(hymn['title'] as String);
    final body = '"${_firstMeaningfulLine(hymn['lyrics'] as String)}"';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_hymn_channel',
      'Daily Hymn',
      channelDescription: 'Daily reminder to read and sing hymns.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      _dailyHymnNotifId,
      '🎵 $title',
      body,
      _nextOccurrence(time),
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
  }

  /// Cancel the daily notification and clear the saved preference.
  Future<void> cancelDailyHymnNotification() async {
    await _plugin.cancel(_dailyHymnNotifId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  /// Re-schedule with fresh hymn content if notifications are enabled.
  /// Call this on every app open so the content rotates daily.
  Future<void> rescheduleDailyHymnIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (!enabled) return;
    final time = TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? 8,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
    await scheduleDailyHymnNotification(time);
  }

  Future<bool> isDailyNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<TimeOfDay> getSavedNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? 8,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Pick today's hymn deterministically using day-of-year.
  Map _hymnOfDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return hymnJson[dayOfYear % hymnJson.length] as Map;
  }

  /// Returns the next [TZDateTime] matching [time] (today or tomorrow).
  tz.TZDateTime _nextOccurrence(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Strips verse numbers / "Antiphon" headers and returns the first real line.
  String _firstMeaningfulLine(String lyrics) {
    final lines = lyrics.split('\n').map((l) {
      return l
          .replaceFirst(RegExp(r'^(Antiphon\s*\d*:?\s*|\d+\.\s*)'), '')
          .trim();
    }).where((l) => l.isNotEmpty);
    return lines.isNotEmpty ? lines.first : lyrics.split('\n').first.trim();
  }

  String _toTitleCase(String s) {
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
