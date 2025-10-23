import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:kl_recycling_app/services/firebase_service.dart';

class NotificationService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _weeklySummaryEnabledKey = 'weekly_summary_enabled';
  static const String _achievementEnabledKey = 'achievement_enabled';
  static const String _tipsEnabledKey = 'tips_enabled';
  static const String _reminderHourKey = 'reminder_hour';
  static const String _reminderMinuteKey = 'reminder_minute';

  static FlutterLocalNotificationsPlugin? _localNotifications;
  static StreamSubscription<RemoteMessage>? _firebaseSubscription;

  // Eco-friendly tips database
  static const List<String> _ecoTips = [
    '🍃 Did you know? Recycling one aluminum can saves enough energy to run a TV for 3 hours!',
    '♻️ Tip: Rinse your plastics before recycling - clean materials are easier to process!',
    '🌱 Fact: Americans use 80 trillion aluminum soda cans every year... ⅓ end up in landfills!',
    '💚 Remember: Just one recycled bottle can save enough energy to power a computer for 25 minutes!',
    '🌍 Impact: Paper recycling saves trees! Each ton of recycled paper saves 17 trees.',
    '📱 Tech hack: Set up a recycling station next to your trash - convenient = more recycling!',
    '🏠 Home tip: Start a compost pile for food scraps and yard waste instead of landfill!',
    '📊 Data point: Recycling all newspaper for 1 year would save half the trees cut down annually!',
    '🎯 Goal: Aim to recycle at least 50% of your household waste this week!',
    '💡 Pro tip: Create designated recycling bags for different materials - makes sorting easier!',
  ];

  // Achievement notifications
  static const List<String> _achievementMessages = [
    '🏆 Eco Warrior Achievement Unlocked!',
    '🌟 Sustainability Champion Level Up!',
    '🎉 Recycling Milestone Reached!',
    '⭐ Badge Earned - Keep Going!',
    '💪 Environmental Hero Status!',
  ];

  static FlutterLocalNotificationsPlugin get localNotifications {
    _localNotifications ??= FlutterLocalNotificationsPlugin();
    return _localNotifications!;
  }

  /// Initialize notification services
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();

    // Request permissions
    await _requestPermissions();

    debugPrint('NotificationService initialized');
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    // Local notifications permissions
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestNotificationsPermission();
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }

    // Firebase permissions (already requested in FirebaseService)
  }

  /// Initialize Firebase messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    _firebaseSubscription = FirebaseMessaging.onMessage.listen(_onFirebaseMessage);

    // Handle message open
    FirebaseMessaging.onMessageOpenedApp.listen(_onFirebaseMessageOpened);

    // Get initial message (if app was opened from notification)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _onFirebaseMessageOpened(initialMessage);
    }
  }

  /// Handle Firebase background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Firebase background message: ${message.messageId}');

    // Convert Firebase message to local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'KL Recycling',
      body: message.notification?.body ?? 'You have a new notification',
      payload: json.encode(message.data),
    );
  }

  /// Handle Firebase foreground messages
  static Future<void> _onFirebaseMessage(RemoteMessage message) async {
    debugPrint('Firebase foreground message: ${message.messageId}');

    // Convert Firebase message to local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'KL Recycling',
      body: message.notification?.body ?? 'You have a new notification',
      payload: json.encode(message.data),
    );
  }

  /// Handle Firebase message opened
  static void _onFirebaseMessageOpened(RemoteMessage message) {
    debugPrint('Firebase message opened: ${message.messageId}');

    // Handle navigation based on message data
    final data = message.data;
    if (data.containsKey('screen')) {
      // Navigate to specific screen
      // This would be handled by the app navigation logic
    }
  }

  /// Handle local notification tapped
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    // Handle navigation based on payload
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        if (data.containsKey('screen')) {
          // Navigate to specific screen
          // This would be handled by the app navigation logic
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kl_recycling_channel',
      'KL Recycling Notifications',
      channelDescription: 'Notifications for KL Recycling app',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF4CAF50),
      ledOnMs: 1000,
      ledOffMs: 500,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final randomId = Random().nextInt(100000);

    await localNotifications.show(
      randomId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // RECYCLING REMINDERS

  /// Schedule daily recycling reminder
  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    bool enabled = true,
  }) async {
    await _cancelReminderNotification(1000); // Cancel existing

    if (!enabled) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    final nextTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await localNotifications.zonedSchedule(
      1000,
      'Time to Recycle! ♻️',
      'Don\'t forget to check for recyclable items today!',
      nextTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Recycling Reminders',
          channelDescription: 'Daily recycling reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: json.encode({'type': 'reminder'}),
    );

    debugPrint('Daily reminder scheduled for $nextTime');
  }

  /// Send eco tip notification
  static Future<void> sendEcoTip() async {
    final tip = _ecoTips[Random().nextInt(_ecoTips.length)];

    await _showLocalNotification(
      title: '🌱 Eco Tip of the Day',
      body: tip,
      payload: json.encode({'type': 'tip'}),
    );
  }

  /// Send achievement notification
  static Future<void> sendAchievementNotification({
    required String achievementTitle,
    required String description,
  }) async {
    await _showLocalNotification(
      title: '🏆 Achievement Unlocked!',
      body: '$achievementTitle - $description',
      payload: json.encode({
        'type': 'achievement',
        'title': achievementTitle,
        'description': description,
      }),
    );
  }

  /// Send weekly progress summary
  static Future<void> sendWeeklySummary({
    required int pointsEarned,
    required int itemsRecycled,
    required double weightSaved,
    required List<String> topMaterials,
  }) async {
    final summary = '''
Weekly Summary:
• $pointsEarned points earned
• $itemsRecycled items recycled
• ${weightSaved.toStringAsFixed(1)} lbs diverted from landfill
• Top materials: ${topMaterials.join(', ')}
''';

    await _showLocalNotification(
      title: '📊 Your Weekly Impact',
      body: summary,
      payload: json.encode({
        'type': 'summary',
        'points': pointsEarned,
        'items': itemsRecycled,
        'weight': weightSaved,
      }),
    );
  }

  /// Send environmental milestone notification
  static Future<void> sendMilestoneNotification({
    required String milestoneType,
    required int value,
    required String unit,
  }) async {
    final messages = {
      'trees': '🌳 $value trees saved this month! Keep up the amazing work!',
      'energy': '⚡ Saved enough energy to power $value homes for a day!',
      'waste': '♻️ Diverted $value lbs from landfill - you\'re making a difference!',
      'co2': '🌍 Reduced CO₂ emissions by $value tons - planet thanks you!',
    };

    final message = messages[milestoneType] ?? '🎯 Environmental milestone reached: $value $unit!';

    await _showLocalNotification(
      title: '🌍 Environmental Milestone!',
      body: message,
      payload: json.encode({
        'type': 'milestone',
        'milestoneType': milestoneType,
        'value': value,
        'unit': unit,
      }),
    );
  }

  // SETTINGS MANAGEMENT

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  /// Enable/disable all notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (!enabled) {
      await localNotifications.cancelAll();
    }
  }

  /// Check if reminder notifications are enabled
  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? true;
  }

  /// Enable/disable reminder notifications
  static Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);

    if (enabled) {
      final reminderTime = await getReminderTime();
      await scheduleDailyReminder(time: reminderTime, enabled: enabled);
    } else {
      await _cancelReminderNotification(1000);
    }
  }

  /// Get reminder time
  static Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_reminderHourKey) ?? 19; // 7 PM default
    final minute = prefs.getInt(_reminderMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Set reminder time
  static Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);

    final enabled = await isReminderEnabled();
    if (enabled) {
      await scheduleDailyReminder(time: time, enabled: enabled);
    }
  }

  /// Check if weekly summary notifications are enabled
  static Future<bool> isWeeklySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weeklySummaryEnabledKey) ?? true;
  }

  /// Enable/disable weekly summary notifications
  static Future<void> setWeeklySummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklySummaryEnabledKey, enabled);
  }

  /// Check if achievement notifications are enabled
  static Future<bool> isAchievementEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_achievementEnabledKey) ?? true;
  }

  /// Enable/disable achievement notifications
  static Future<void> setAchievementEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_achievementEnabledKey, enabled);
  }

  /// Check if eco tips notifications are enabled
  static Future<bool> isTipsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tipsEnabledKey) ?? true;
  }

  /// Enable/disable eco tips notifications
  static Future<void> setTipsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tipsEnabledKey, enabled);
  }

  /// Schedule weekly eco tip (Sunday at 10 AM)
  static Future<void> scheduleWeeklyTip() async {
    final enabled = await isTipsEnabled();
    await _cancelReminderNotification(2000); // Cancel existing

    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final sunday = now.add(Duration(days: (7 - now.weekday) % 7));
    final scheduledTime = tz.TZDateTime(
      tz.local,
      sunday.year,
      sunday.month,
      sunday.day,
      10, // 10 AM
      0,
    );

    await localNotifications.zonedSchedule(
      2000,
      '🌱 Weekly Eco Tip',
      'Learn something new to help the planet this week!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tips_channel',
          'Eco Tips',
          channelDescription: 'Weekly eco-friendly tips',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: json.encode({'type': 'weekly_tip'}),
    );

    debugPrint('Weekly tip scheduled for $scheduledTime');
  }

  /// Cancel specific notification
  static Future<void> _cancelReminderNotification(int id) async {
    await localNotifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await localNotifications.cancelAll();
  }

  /// Get notification settings summary
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'notificationsEnabled': prefs.getBool(_notificationsEnabledKey) ?? false,
      'reminderEnabled': prefs.getBool(_reminderEnabledKey) ?? true,
      'weeklySummaryEnabled': prefs.getBool(_weeklySummaryEnabledKey) ?? true,
      'achievementEnabled': prefs.getBool(_achievementEnabledKey) ?? true,
      'tipsEnabled': prefs.getBool(_tipsEnabledKey) ?? true,
      'reminderHour': prefs.getInt(_reminderHourKey) ?? 19,
      'reminderMinute': prefs.getInt(_reminderMinuteKey) ?? 0,
    };
  }

  /// Dispose and cleanup
  static Future<void> dispose() async {
    await _firebaseSubscription?.cancel();
  }
}
