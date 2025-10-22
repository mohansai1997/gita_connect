import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to send real FCM push notifications using simplified legacy API
/// This enables notifications even when the app is closed
class FCMPushService {
  // 🔑 GET YOUR SERVER KEY FROM: 
  // Google Cloud Console → APIs & Credentials → Credentials 
  // Look for "Server key" or create new "API Key" with FCM access
  // Direct link: https://console.cloud.google.com/apis/credentials?project=gita-connect
  static const String _serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Send push notification to specific FCM token
  static Future<bool> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    String? priority,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if server key is configured
      if (_serverKey == 'YOUR_FIREBASE_SERVER_KEY_HERE') {
        print('! FCM Server Key not configured. Skipping push notification.');
        return false;
      }

      final payload = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': priority ?? 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 1) {
          print('✅ FCM push notification sent successfully');
          return true;
        } else {
          print('❌ FCM push failed: ${responseData['results'][0]['error']}');
          return false;
        }
      } else {
        print('❌ FCM HTTP error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending FCM push notification: $e');
      return false;
    }
  }

  /// Send push notification to multiple FCM tokens
  static Future<int> sendPushNotificationToMultiple({
    required List<String> fcmTokens,
    required String title,
    required String body,
    String? priority,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if server key is configured
      if (_serverKey == 'YOUR_FIREBASE_SERVER_KEY_HERE') {
        print('! FCM Server Key not configured. Skipping push notifications.');
        return 0;
      }

      final payload = {
        'registration_ids': fcmTokens,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': priority ?? 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final successCount = responseData['success'] ?? 0;
        print('✅ FCM push notifications sent: $successCount/${fcmTokens.length}');
        return successCount;
      } else {
        print('❌ FCM batch HTTP error: ${response.statusCode} ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❌ Error sending FCM batch notifications: $e');
      return 0;
    }
  }

  /// Send push notification to a topic
  static Future<bool> sendPushNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    String? priority,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if server key is configured
      if (_serverKey == 'YOUR_FIREBASE_SERVER_KEY_HERE') {
        print('! FCM Server Key not configured. Skipping topic notification.');
        return false;
      }

      final payload = {
        'to': '/topics/$topic',
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': priority ?? 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message_id'] != null) {
          print('✅ FCM topic notification sent successfully');
          return true;
        } else {
          print('❌ FCM topic failed: ${responseData}');
          return false;
        }
      } else {
        print('❌ FCM topic HTTP error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending FCM topic notification: $e');
      return false;
    }
  }

  /// Test FCM configuration
  static Future<bool> testFCMConfiguration() async {
    try {
      if (_serverKey == 'YOUR_FIREBASE_SERVER_KEY_HERE') {
        print('❌ FCM Server Key not configured');
        return false;
      }

      // Send a dry-run request to validate the key
      final testPayload = {
        'to': 'test_token_12345',
        'dry_run': true,
        'notification': {
          'title': 'Test',
          'body': 'FCM Configuration Test',
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(testPayload),
      );

      if (response.statusCode == 200) {
        print('✅ FCM Server Key is valid and configured correctly');
        return true;
      } else if (response.statusCode == 401) {
        print('❌ FCM Server Key is invalid or unauthorized');
        return false;
      } else {
        print('⚠️ FCM test response: ${response.statusCode} ${response.body}');
        return true; // Server key is likely valid, just test token was invalid
      }
    } catch (e) {
      print('❌ FCM configuration test error: $e');
      return false;
    }
  }
}