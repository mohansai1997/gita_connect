import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Set timezone to IST
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _initialized = true;
    debugPrint('✅ Notification service initialized');
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific screen
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    // Request notification permission
    final PermissionStatus status = await Permission.notification.request();
    
    if (status.isGranted) {
      debugPrint('✅ Notification permissions granted');
      
      // Also check for exact alarm permission on Android 12+
      try {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (exactAlarmStatus.isDenied) {
          debugPrint('⚠️ Exact alarm permission not granted - notifications may be approximate');
          // Note: We don't force request this as it requires user to go to system settings
        } else {
          debugPrint('✅ Exact alarm permission available');
        }
      } catch (e) {
        debugPrint('ℹ️ Exact alarm permission check not available (older Android version)');
      }
      
      return true;
    } else {
      debugPrint('❌ Notification permissions denied');
      return false;
    }
  }

  /// Schedule daily Krishna consciousness notification at 10:07 PM IST
  static Future<void> scheduleDailyKrishnaReminder() async {
    try {
      // Cancel ALL existing notifications to avoid duplicates and conflicts
      await _notifications.cancelAll();
      debugPrint('🗑️ Cleared all existing notifications');
      
      // Create notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_krishna_reminder',
        'Daily Krishna Reminder',
        channelDescription: 'Daily spiritual reminders for Krishna consciousness',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Calculate next 10:07 PM IST
      final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation('Asia/Kolkata'));
      debugPrint('🕐 Current IST time: ${now.toString()}');
      
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.getLocation('Asia/Kolkata'),
        now.year,
        now.month,
        now.day,
        22, // Hour: 10 PM (22 in 24-hour format)
        12, // Minute: 07
      );
      
      debugPrint('⏰ Target time today would be: ${scheduledDate.toString()}');
      
      // If 10:07 PM today has passed, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('⏭️ Time has passed today, scheduling for tomorrow: ${scheduledDate.toString()}');
      } else {
        debugPrint('✅ Scheduling for today: ${scheduledDate.toString()}');
      }
      
      // Schedule the notification with fallback for exact alarm permission
      try {
        await _notifications.zonedSchedule(
          1, // Notification ID
          'Hare Krishna! 🙏', // Title
          'Start your day with Krishna consciousness', // Body
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
          payload: 'daily_krishna_reminder',
        );
        debugPrint('✅ Daily notification scheduled (exact timing)');
      } catch (exactAlarmError) {
        debugPrint('⚠️ Exact alarms not permitted for daily reminder, using approximate timing');
        
        // Fallback: Use approximate scheduling  
        await _notifications.zonedSchedule(
          1, // Notification ID
          'Hare Krishna! 🙏', // Title
          'Start your day with Krishna consciousness', // Body
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'daily_krishna_reminder',
        );
        debugPrint('✅ Daily notification scheduled (approximate timing)');
      }
      
      debugPrint('✅ Daily Krishna reminder scheduled for ${scheduledDate.toString()}');
      
      // Schedule multiple notifications for the next 30 days to ensure continuity
      await _scheduleMultipleDays();
      
    } catch (e) {
      debugPrint('❌ Error scheduling daily reminder: $e');
    }
  }

  /// Schedule notifications for the next 30 days to ensure continuity
  static Future<void> _scheduleMultipleDays() async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation('Asia/Kolkata'));
      
      for (int i = 1; i <= 30; i++) {
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.getLocation('Asia/Kolkata'),
          now.year,
          now.month,
          now.day + i,
          22, // Hour: 11 PM (23 in 24-hour format)
          12, // Minute: 46
        );
        
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'daily_krishna_reminder',
          'Daily Krishna Reminder',
          channelDescription: 'Daily spiritual reminders for Krishna consciousness',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        
        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
        );
        
        // Use inexact scheduling for multi-day notifications to be more battery friendly
        await _notifications.zonedSchedule(
          100 + i, // Unique ID for each day
          'Hare Krishna! 🙏',
          'Start your day with Krishna consciousness',
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'daily_krishna_reminder_day_$i',
        );
      }
      
      debugPrint('✅ Scheduled notifications for next 30 days (battery-optimized)');
      
    } catch (e) {
      debugPrint('❌ Error scheduling multiple days: $e');
    }
  }

  /// Check if notifications are scheduled
  static Future<void> checkScheduledNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications = 
        await _notifications.pendingNotificationRequests();
    
    debugPrint('📋 Pending notifications: ${pendingNotifications.length}');
    
    final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation('Asia/Kolkata'));
    debugPrint('🕐 Current IST time: ${now.toString()}');
    
    for (final notification in pendingNotifications) {
      debugPrint('  - ID: ${notification.id}');
      debugPrint('    Title: ${notification.title}');
      debugPrint('    Body: ${notification.body}');
      debugPrint('    Payload: ${notification.payload}');
    }
    
    if (pendingNotifications.isEmpty) {
      debugPrint('⚠️ No notifications scheduled! This could be why you\'re not getting notifications.');
    }
  }

  /// Test scheduled notification (2 minutes from now)
  static Future<void> scheduleTestNotificationIn2Minutes() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_scheduled_channel',
        'Test Scheduled Notifications',
        channelDescription: 'Test scheduled notifications for Krishna consciousness app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation('Asia/Kolkata'));
      final tz.TZDateTime scheduledTime = now.add(const Duration(minutes: 2));
      
      // Try exact scheduling first, fallback to approximate if not permitted
      try {
        await _notifications.zonedSchedule(
          888, // Test scheduled notification ID
          'Test Scheduled - Hare Krishna! 🙏',
          'This scheduled test notification proves scheduling works!',
          scheduledTime,
          notificationDetails,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'test_scheduled_notification',
        );
        debugPrint('✅ Test notification scheduled (exact) for: ${scheduledTime.toString()}');
      } catch (exactAlarmError) {
        debugPrint('⚠️ Exact alarms not permitted, using approximate scheduling');
        
        // Fallback: Use approximate scheduling
        await _notifications.zonedSchedule(
          888, // Test scheduled notification ID
          'Test Scheduled - Hare Krishna! 🙏',
          'This scheduled test notification (approximate timing)',
          scheduledTime,
          notificationDetails,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'test_scheduled_notification',
        );
        debugPrint('✅ Test notification scheduled (approximate) for: ${scheduledTime.toString()}');
      }
      
      debugPrint('⏰ That is in 2 minutes from now');
    } catch (e) {
      debugPrint('❌ Error scheduling test notification: $e');
      rethrow;
    }
  }

  /// Test immediate notification
  static Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notifications for Krishna consciousness app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        999, // Test notification ID
        'Test - Hare Krishna! 🙏',
        'This is a test notification for Krishna consciousness',
        notificationDetails,
        payload: 'test_notification',
      );
      
      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  /// Get battery optimization info for the user
  static String getBatteryOptimizationGuidance() {
    return '''
📱 For reliable daily notifications:

1. Go to Phone Settings → Apps → Gita Connect
2. Battery → "Don't optimize" or "Unrestricted"  
3. Notifications → Enable all permissions
4. Some phones: Auto-start → Enable

This prevents Android from delaying notifications to save battery.

Note: Notifications may arrive 1-2 minutes late on some devices due to Android's battery optimization. This is normal behavior.
    ''';
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }
}