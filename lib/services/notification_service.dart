import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Simplified Local Notification Service
/// Handles only immediate notifications and foreground display
/// Server-side FCM handles all scheduled notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Initialize local notifications for immediate testing and foreground display
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: false, // FCM handles permissions
          requestBadgePermission: false,
          requestSoundPermission: false,
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
    debugPrint('✅ Local notification service initialized (for testing only)');
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Local notification tapped: ${response.payload}');
  }

  /// Test immediate notification (for testing only)
  static Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test local notifications for Krishna consciousness app',
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
        'Test Local - Hare Krishna! 🙏',
        'This is a local test notification (FCM handles scheduled ones)',
        notificationDetails,
        payload: 'test_local_notification',
      );
      
      debugPrint('✅ Local test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  /// Show FCM notification in foreground (when app is open)
  static Future<void> showForegroundNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fcm_foreground_channel',
        'FCM Foreground Notifications',
        channelDescription: 'Display FCM notifications when app is in foreground',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID based on timestamp
        title,
        body,
        notificationDetails,
        payload: 'fcm_foreground',
      );
      
      debugPrint('✅ FCM foreground notification displayed: $title');
    } catch (e) {
      debugPrint('❌ Error showing FCM foreground notification: $e');
    }
  }

  /// Cancel all local notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All local notifications cancelled');
  }
}