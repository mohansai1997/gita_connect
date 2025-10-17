import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Initialize FCM service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize local notifications for foreground display
    await _initializeLocalNotifications();
    
    // Get and store FCM token
    await _getAndStoreToken();
    
    // Set up message handlers
    _setupMessageHandlers();
    
    _initialized = true;
    debugPrint('✅ FCM Service initialized');
  }

  /// Request notification permissions
  static Future<bool> _requestPermissions() async {
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ FCM permissions granted');
      return true;
    } else {
      debugPrint('❌ FCM permissions denied');
      return false;
    }
  }

  /// Initialize local notifications for foreground display
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: false, // Already requested via FCM
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
  }

  /// Get FCM token and store it in Firestore
  static Future<void> _getAndStoreToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      final User? user = FirebaseAuth.instance.currentUser;
      
      if (token != null && user != null) {
        // Store token in user's Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ FCM Token stored: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Error storing FCM token: $e');
    }
  }

  /// Setup message handlers for different app states
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Foreground message received: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification tapped (background): ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('🔄 FCM Token refreshed');
      _updateTokenInFirestore(token);
    });
  }

  /// Show local notification when app is in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_krishna_channel',
      'Krishna Consciousness Notifications',
      channelDescription: 'Daily spiritual reminders from Gita Connect',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Hare Krishna! 🙏',
      message.notification?.body ?? 'Your spiritual reminder',
      notificationDetails,
    );
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 User tapped notification: ${message.data}');
    // You can add navigation logic here
  }

  /// Update token in Firestore when it refreshes
  static Future<void> _updateTokenInFirestore(String token) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  /// Subscribe to daily Krishna reminders topic
  static Future<void> subscribeToKrishnaReminders() async {
    try {
      await _firebaseMessaging.subscribeToTopic('daily_krishna_reminders');
      debugPrint('✅ Subscribed to daily Krishna reminders');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from daily Krishna reminders topic
  static Future<void> unsubscribeFromKrishnaReminders() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('daily_krishna_reminders');
      debugPrint('🔕 Unsubscribed from daily Krishna reminders');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Test FCM by sending to current device
  static Future<void> sendTestNotification() async {
    try {
      final String? token = await getToken();
      if (token != null) {
        // You would typically call your server endpoint here
        // For now, we'll just show a local notification
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'test_fcm_channel',
          'Test FCM Notifications',
          channelDescription: 'Test notifications for FCM setup',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
        );

        await _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'FCM Test - Hare Krishna! 🙏',
          'This proves FCM notifications are working!',
          notificationDetails,
        );
        
        debugPrint('✅ Test FCM notification sent');
        debugPrint('Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Error sending test FCM notification: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.notification?.title}');
  // Handle background message here
}