import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

/// Notification service for local notifications
///
/// **Android Requirements (API 31+):**
/// - SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM permission in AndroidManifest.xml
/// - User must grant "Alarms & reminders" permission in device settings
/// - If permission denied, will throw PlatformException with 'exact_alarms_not_permitted'
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    print('NotificationService: Initializing...');
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const DarwinInitializationSettings macOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    final bool? result = await _notificationsPlugin.initialize(settings);
    print('NotificationService: Initialized with result: $result');

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request notification permissions after plugin initialization
    await _requestNotificationPermission();
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    print(
        'NotificationService: showSimpleNotification called with id=$id, title=$title');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smartfinance_channel',
      'FinTrack Notifications',
      channelDescription: 'Notifications for FinTrack',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      onlyAlertOnce: false,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOSDetails,
    );

    try {
      await _notificationsPlugin.show(id, title, body, details);
      print('NotificationService: Notification shown successfully');
    } catch (e) {
      print('NotificationService: Error showing notification: $e');
      rethrow;
    }
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smartfinance_channel',
      'FinTrack Notifications',
      channelDescription: 'Notifications for FinTrack',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      onlyAlertOnce: false,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleWeeklyNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smartfinance_channel',
      'FinTrack Notifications',
      channelDescription: 'Notifications for FinTrack',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      onlyAlertOnce: false,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.weekly,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Schedule a daily reminder at a specific time
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = "Don't forget to track your expenses!",
    String body = "Log your daily expenses and keep your budget on track.",
  }) async {
    final permissionGranted = await _isNotificationPermissionGranted();
    if (!permissionGranted) {
      throw Exception('notification_permission_denied');
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminders to track expenses',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      onlyAlertOnce: false,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOSDetails,
    );

    // Cancel any existing daily reminder first
    await _notificationsPlugin.cancel(999); // Use ID 999 for daily reminders

    // Schedule the daily reminder
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      999, // Daily reminder ID
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print(
      'NotificationService: Daily reminder scheduled for $scheduledDate (${tz.local.name})',
    );
  }

  /// Cancel the daily reminder
  static Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(999);
  }

  /// Get information about pending scheduled notifications
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Get current notification permission status label
  static Future<String> getNotificationPermissionStatusLabel() async {
    try {
      if (Platform.isIOS) {
        final iosPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final permissions = await iosPlugin?.checkPermissions();
        return _darwinPermissionLabel(permissions);
      }

      if (Platform.isMacOS) {
        final macPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        final permissions = await macPlugin?.checkPermissions();
        return _darwinPermissionLabel(permissions);
      }

      final status = await Permission.notification.status;
      return status.toString().split('.').last;
    } catch (e) {
      print('NotificationService: Error checking notification permission: $e');
      return 'unknown';
    }
  }

  static Future<void> openNotificationSettings() async {
    if (Platform.isAndroid) {
      await openAppSettings();
      return;
    }

    if (Platform.isIOS) {
      await openAppSettings();
      return;
    }

    if (Platform.isMacOS) {
      final notificationSettingsUri =
          Uri.parse('x-apple.systempreferences:com.apple.Notifications');
      if (await canLaunchUrl(notificationSettingsUri)) {
        await launchUrl(notificationSettingsUri);
        return;
      }

      final fallbackUri = Uri.parse(
          'x-apple.systempreferences:com.apple.preference.notifications');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
      }
    }
  }

  /// Request notification permission on Android 13+
  static Future<void> _requestNotificationPermission() async {
    try {
      if (Platform.isIOS) {
        final iosPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('NotificationService: iOS notification permission: $granted');
        return;
      }

      if (Platform.isMacOS) {
        final macPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        final granted = await macPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('NotificationService: macOS notification permission: $granted');
        return;
      }

      final status = await Permission.notification.request();
      print('NotificationService: Notification permission status: $status');
      if (status.isDenied) {
        print('NotificationService: Notification permission denied');
      } else if (status.isGranted) {
        print('NotificationService: Notification permission granted');
      } else if (status.isPermanentlyDenied) {
        print(
            'NotificationService: Notification permission permanently denied - opening app settings');
        openAppSettings();
      }
    } catch (e) {
      print(
          'NotificationService: Error requesting notification permission: $e');
    }
  }

  static Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      print('NotificationService: Local timezone set to $timeZoneName');
    } catch (e) {
      print(
        'NotificationService: Failed to set local timezone, using default: $e',
      );
    }
  }

  static Future<bool> _isNotificationPermissionGranted() async {
    try {
      if (Platform.isIOS) {
        final iosPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final permissions = await iosPlugin?.checkPermissions();
        return permissions?.isEnabled == true ||
            permissions?.isProvisionalEnabled == true;
      }

      if (Platform.isMacOS) {
        final macPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        final permissions = await macPlugin?.checkPermissions();
        return permissions?.isEnabled == true ||
            permissions?.isProvisionalEnabled == true;
      }

      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static String _darwinPermissionLabel(
    NotificationsEnabledOptions? permissions,
  ) {
    if (permissions == null) {
      return 'unknown';
    }

    final hasPermission =
        permissions.isEnabled || permissions.isProvisionalEnabled;
    return hasPermission ? 'granted' : 'denied';
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    try {
      // Main notifications channel
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'smartfinance_channel',
            'FinTrack Notifications',
            description: 'Notifications for FinTrack',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: const Color.fromARGB(255, 0, 136, 200),
          ),
        );

        // Daily reminders channel
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'daily_reminder_channel',
            'Daily Reminders',
            description: 'Daily reminders to track expenses',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: const Color.fromARGB(255, 0, 136, 200),
          ),
        );

        print('NotificationService: Notification channels created');
      } else {
        print('NotificationService: Android plugin not available');
      }
    } catch (e) {
      print('NotificationService: Error creating notification channels: $e');
    }
  }
}
