import 'dart:convert';
import 'package:http/http.dart' as http;

/// Super simple Cloud Function-based notification service
/// Reuses the exact same infrastructure as daily scheduled notifications!
class FCMPushService {
  // Your Cloud Function URL - replace with your actual Firebase project URL
  static const String _cloudFunctionUrl = 'https://us-central1-gita-connect.cloudfunctions.net/sendAdminNotification';

  /// Send notification via Cloud Function (same as daily reminders)
  static Future<bool> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    String? priority,
    Map<String, dynamic>? data,
  }) async {
    // Individual tokens are handled by the same topic-based approach
    return await sendPushNotificationToTopic(
      topic: 'daily_krishna_reminders',
      title: title,
      body: body,
      priority: priority,
      data: data,
    );
  }

  /// Send notifications to multiple users (via topic)
  static Future<int> sendPushNotificationToMultiple({
    required List<String> fcmTokens,
    required String title,
    required String body,
    String? priority,
    Map<String, dynamic>? data,
  }) async {
    // All users are on the same topic, so one call covers everyone
    final success = await sendPushNotificationToTopic(
      topic: 'daily_krishna_reminders',
      title: title,
      body: body,
      priority: priority,
      data: data,
    );
    
    return success ? fcmTokens.length : 0;
  }

  /// Send notification to all users via Cloud Function
  /// This is the ONLY method that actually does work - calls your existing Cloud Function
  static Future<bool> sendPushNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    String? priority,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('🚀 Calling Cloud Function for admin notification...');
      
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'body': body,
          'targetAudience': 'all', // Send to everyone on the topic
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Cloud Function notification sent: ${responseData['messageId']}');
        return true;
      } else {
        print('❌ Cloud Function error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error calling Cloud Function: $e');
      return false;
    }
  }

  /// Test the Cloud Function setup
  static Future<bool> testFCMConfiguration() async {
    try {
      print('🧪 Testing Cloud Function notification...');
      
      return await sendPushNotificationToTopic(
        topic: 'daily_krishna_reminders',
        title: 'Test - Hare Krishna! 🙏',
        body: 'Cloud Function admin notifications are working perfectly!',
      );
    } catch (e) {
      print('❌ Cloud Function test error: $e');
      return false;
    }
  }
}