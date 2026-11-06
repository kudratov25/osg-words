import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'osg_default';

/// Thin wrapper around flutter_local_notifications: init, permissions, and
/// scheduling. All scheduling decisions (ids, recurrence, merging) live in
/// [NotificationScheduler] - this class just talks to the OS.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Channel texts (shown in Android's notification settings), in the
  // interface language - see [setChannelTexts].
  String _channelName = 'Reminders & Vocabulary';
  String _channelDescription = 'Vocabulary words and task reminders';

  /// Updates the channel's name/description (e.g. after the interface
  /// language changed). Re-creating a channel with the same id only
  /// renames it on Android; settings the user changed are kept.
  Future<void> setChannelTexts({required String name, required String description}) async {
    _channelName = name;
    _channelDescription = description;
    if (_initialized) await _createChannel();
  }

  Future<void> _createChannel() async {
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ));
  }

  /// [onTap] fires when the user taps one of our notifications - both while
  /// the app is running and when the tap is what launched the app.
  Future<void> init({void Function()? onTap}) async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) onTap?.call();

    await _createChannel();
    _initialized = true;
  }

  /// Requests notification + exact-alarm permission on Android and
  /// notification permission on iOS. Safe to call repeatedly - the OS
  /// no-ops if already granted/denied.
  ///
  /// Returns whether notifications may be shown (true when unknown).
  Future<bool> requestPermissions() async {
    final android = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final iosGranted = await plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return androidGranted ?? iosGranted ?? true;
  }

  Future<bool> hasExactAlarmPermission() async {
    final granted = await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications();
    return granted ?? true;
  }

  Future<void> cancel(int id) => plugin.cancel(id);

  /// Ids of notifications scheduled but not yet shown.
  Future<Set<int>> pendingIds() async =>
      (await plugin.pendingNotificationRequests()).map((r) => r.id).toSet();

  /// Exact timing needs the "Alarms & reminders" permission on Android 12+.
  /// Without it, fall back to inexact (may arrive some minutes late)
  /// rather than failing to schedule at all.
  Future<AndroidScheduleMode> _scheduleMode() async =>
      await hasExactAlarmPermission() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Schedules a single, non-repeating notification at [at]. Used for
  /// "once" reminders and for vocab notifications, whose content changes
  /// daily so they're rescheduled fresh rather than left recurring.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    return plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      _details(),
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}
