import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'fcm_push_service.dart';

/// Admin Notification Management Service
/// Handles notification creation, templates, analytics for admin panel
class AdminNotificationService {
  static const String _notificationsCollection = 'admin_notifications';
  static const String _templatesCollection = 'notification_templates';
  static const String _scheduledCollection = 'scheduled_notifications';

  /// Send immediate notification to all users
  static Future<bool> sendImmediateNotification({
    required String title,
    required String body,
    required String targetAudience,
    required String priority,
    String? adminId,
  }) async {
    try {
      print('DEBUG: Starting notification send process - Title: $title');
      
      // Store notification in Firestore first
      final notificationRef = await FirebaseFirestore.instance
          .collection(_notificationsCollection)
          .add({
        'title': title,
        'body': body,
        'type': 'immediate',
        'targetAudience': targetAudience,
        'priority': priority,
        'sentAt': FieldValue.serverTimestamp(),
        'createdBy': adminId ?? 'admin',
        'status': 'sending',
        'recipientCount': 0, // Will be updated
        'deliveryStats': {
          'sent': 0,
          'delivered': 0,
          'opened': 0,
        },
      });

      print('DEBUG: Notification stored with ID: ${notificationRef.id}');
      
      // Use a hybrid approach: FCM Topics + Individual user targeting
      bool success = false;
      int targetCount = 0;
      
      // Method 1: Try FCM Topics (works for broad targeting)
      if (targetAudience == 'All Users') {
        success = await _sendToAllUsersViaTopic(title, body, priority);
        if (success) {
          // Get approximate user count
          final allUsers = await _getTargetUsers(targetAudience);
          targetCount = allUsers.length;
        }
      } else {
        // Method 2: Individual user targeting for specific audiences
        final targetUsers = await _getTargetUsers(targetAudience);
        print('DEBUG: Found ${targetUsers.length} target users for $targetAudience');
        targetCount = targetUsers.length;
        
        if (targetUsers.isNotEmpty) {
          int successCount = 0;
          for (final userDoc in targetUsers) {
            final userSuccess = await _sendNotificationToUser(
              userDoc: userDoc,
              title: title,
              body: body,
              priority: priority,
            );
            if (userSuccess) successCount++;
          }
          success = successCount > 0;
          print('DEBUG: Individual sending: $successCount/${targetUsers.length} successful');
        }
      }
      
      // Update notification status
      await notificationRef.update({
        'status': success ? 'sent' : 'failed',
        'recipientCount': targetCount,
        'deliveryStats.sent': success ? targetCount : 0,
      });
      
      print('DEBUG: Final result - Success: $success, Target count: $targetCount');
      return success;
    } catch (e) {
      print('ERROR sending notification: $e');
      return false;
    }
  }

  /// Get notification history with pagination
  static Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      print('DEBUG: Getting notification history');
      
      Query query = FirebaseFirestore.instance
          .collection(_notificationsCollection)
          .orderBy('sentAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.get();
      
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('DEBUG: Found ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      print('ERROR getting notification history: $e');
      return [];
    }
  }

  /// Get notification analytics/stats
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      print('DEBUG: Getting notification statistics');
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_notificationsCollection)
          .get();
      
      int totalSent = 0;
      int totalDelivered = 0;
      int totalOpened = 0;
      int thisWeekCount = 0;
      
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deliveryStats = data['deliveryStats'] as Map<String, dynamic>? ?? {};
        
        totalSent += (deliveryStats['sent'] as int? ?? 0);
        totalDelivered += (deliveryStats['delivered'] as int? ?? 0);
        totalOpened += (deliveryStats['opened'] as int? ?? 0);
        
        // Count notifications from this week
        final sentAt = data['sentAt'] as Timestamp?;
        if (sentAt != null && sentAt.toDate().isAfter(weekAgo)) {
          thisWeekCount++;
        }
      }
      
      // Count successful notifications
      int successfulNotifications = 0;
      int adminOnlyNotifications = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final targetAudience = data['targetAudience'] as String?;
        
        if (status == 'sent') {
          successfulNotifications++;
        }
        
        if (targetAudience == 'Admins Only') {
          adminOnlyNotifications++;
        }
      }
      
      final stats = {
        'totalNotifications': snapshot.docs.length,
        'totalSent': totalSent,
        'thisWeekCount': thisWeekCount,
        'successfulNotifications': successfulNotifications,
        'successRate': snapshot.docs.length > 0 ? (successfulNotifications / snapshot.docs.length * 100).round() : 0,
        'adminOnlyCount': adminOnlyNotifications,
      };
      
      print('DEBUG: Notification stats: $stats');
      return stats;
    } catch (e) {
      print('ERROR getting notification stats: $e');
      return {
        'totalNotifications': 0,
        'totalSent': 0,
        'thisWeekCount': 0,
        'successfulNotifications': 0,
        'successRate': 0,
        'adminOnlyCount': 0,
      };
    }
  }

  /// Create notification template
  static Future<bool> createTemplate({
    required String name,
    required String title,
    required String body,
    required String category,
  }) async {
    try {
      print('DEBUG: Creating notification template: $name in collection: $_templatesCollection');
      
      final docRef = await FirebaseFirestore.instance
          .collection(_templatesCollection)
          .add({
        'name': name,
        'title': title,
        'body': body,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      print('DEBUG: Template created successfully with ID: ${docRef.id}');
      print('DEBUG: Template data: {name: $name, title: $title, body: $body, category: $category}');
      return true;
    } catch (e) {
      print('ERROR creating template: $e');
      print('ERROR Stack trace: ${e.toString()}');
      return false;
    }
  }

  /// Get notification templates
  static Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      print('DEBUG: Getting notification templates from collection: $_templatesCollection');
      print('DEBUG: Collection name resolved to: notification_templates');
      
      // Test basic collection access like other collections do
      final snapshot = await FirebaseFirestore.instance
          .collection('notification_templates')  // Use direct string like other collections
          .get();
      
      print('DEBUG: Raw snapshot has ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('DEBUG: No documents found - checking if collection exists or has any data');
        
        // Try to test with a different collection that we know works
        final testSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .limit(1)
            .get();
        print('DEBUG: Test users collection has ${testSnapshot.docs.length} documents (should be > 0)');
      }
      
      final templates = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('DEBUG: Template doc ${doc.id}: ${data.toString()}');
        return data;
      }).toList();
      
      // Sort by createdAt locally (no need to filter by isActive since we delete permanently)
      templates.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      print('DEBUG: Returning ${templates.length} templates');
      return templates;
    } catch (e) {
      print('ERROR getting templates: $e');
      print('ERROR Stack trace: ${e.toString()}');
      return [];
    }
  }

  /// Delete notification template
  static Future<bool> deleteTemplate(String templateId) async {
    try {
      print('DEBUG: Permanently deleting template: $templateId');
      
      await FirebaseFirestore.instance
          .collection(_templatesCollection)
          .doc(templateId)
          .delete();
      
      print('DEBUG: Template deleted permanently from database');
      return true;
    } catch (e) {
      print('ERROR deleting template: $e');
      return false;
    }
  }

  /// Get recent notifications for dashboard
  static Future<List<Map<String, dynamic>>> getRecentNotifications({int limit = 5}) async {
    try {
      print('DEBUG: Getting recent notifications for dashboard');
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_notificationsCollection)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();
      
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('DEBUG: Found ${notifications.length} recent notifications');
      return notifications;
    } catch (e) {
      print('ERROR getting recent notifications: $e');
      return [];
    }
  }

  /// Schedule notification for later
  static Future<bool> scheduleNotification({
    required String title,
    required String body,
    required String targetAudience,
    required String priority,
    required DateTime scheduledFor,
    String? adminId,
  }) async {
    try {
      print('DEBUG: Scheduling notification for: $scheduledFor');
      
      await FirebaseFirestore.instance
          .collection(_notificationsCollection)
          .add({
        'title': title,
        'body': body,
        'type': 'scheduled',
        'targetAudience': targetAudience,
        'priority': priority,
        'scheduledFor': Timestamp.fromDate(scheduledFor),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminId ?? 'admin',
        'status': 'scheduled',
        'recipientCount': 0,
        'deliveryStats': {
          'sent': 0,
          'delivered': 0,
          'opened': 0,
        },
      });
      
      print('DEBUG: Notification scheduled successfully');
      return true;
    } catch (e) {
      print('ERROR scheduling notification: $e');
      return false;
    }
  }

  /// Get default notification templates
  static List<Map<String, String>> getDefaultTemplates() {
    return [
      {
        'name': 'Daily Krishna Reminder',
        'title': 'Hare Krishna! 🙏',
        'body': 'Remember to chant and meditate today. Krishna is always with you.',
        'category': 'Daily Spiritual'
      },
      {
        'name': 'New Video Uploaded',
        'title': 'New Spiritual Video Available! 📺',
        'body': 'We\'ve uploaded a new video for your spiritual growth. Check it out now!',
        'category': 'Content Updates'
      },
      {
        'name': 'Festival Reminder',
        'title': 'Upcoming Festival Celebration 🎉',
        'body': 'Join us for the upcoming festival celebration. Don\'t miss this divine opportunity!',
        'category': 'Festivals'
      },
      {
        'name': 'Bhagavad Gita Quote',
        'title': 'Daily Wisdom from Bhagavad Gita 📖',
        'body': 'Today\'s verse brings divine wisdom for your spiritual journey.',
        'category': 'Spiritual Quotes'
      },
      {
        'name': 'Gallery Updated',
        'title': 'New Photos Added to Gallery 📸',
        'body': 'Beautiful new photos have been added to our gallery. Take a look!',
        'category': 'Content Updates'
      }
    ];
  }

  /// Test FCM configuration
  static Future<bool> testFCMConfiguration() async {
    return await FCMPushService.testFCMConfiguration();
  }

  /// Get target users based on audience selection
  static Future<List<QueryDocumentSnapshot>> _getTargetUsers(String targetAudience) async {
    try {
      Query query = FirebaseFirestore.instance.collection('users');
      
      switch (targetAudience) {
        case 'Admins Only':
          query = query.where('userType', isEqualTo: 'Admin');
          break;
        case 'All Users':
        default:
          // No additional filter - get all users
          break;
      }
      
      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      print('ERROR getting target users: $e');
      return [];
    }
  }

  /// Send notification to a specific user
  static Future<bool> _sendNotificationToUser({
    required QueryDocumentSnapshot userDoc,
    required String title,
    required String body,
    required String priority,
  }) async {
    try {
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('WARNING: User ${userDoc.id} has no FCM token');
        return false;
      }
      
      // Method 1: Send REAL FCM Push Notification (works when app is closed)
      final pushSuccess = await FCMPushService.sendPushNotification(
        fcmToken: fcmToken,
        title: title,
        body: body,
        priority: priority,
        data: {
          'type': 'admin_notification',
          'userId': userDoc.id,
        },
      );

      // Method 2: Store in Firestore for app-based notifications (backup)
      await FirebaseFirestore.instance
          .collection('user_notifications')
          .doc(userDoc.id)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'priority': priority,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
        'fcmToken': fcmToken,
        'pushSent': pushSuccess,
      });

      // Method 3: Local notification if this is the current user (immediate feedback)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && userDoc.id == currentUser.uid) {
        print('DEBUG: Sending local notification to current user');
        await NotificationService.showForegroundNotification(title, body);
      }
      
      if (pushSuccess) {
        print('✅ FCM Push + Firestore notification sent to user ${userDoc.id}');
      } else {
        print('⚠️ FCM Push failed, but Firestore notification stored for user ${userDoc.id}');
      }
      
      return true; // Return true if at least Firestore storage succeeded
      
    } catch (e) {
      print('ERROR sending notification to user ${userDoc.id}: $e');
      return false;
    }
  }

  /// Send notifications to all users via FCM Topic (Cloud Function)
  static Future<bool> _sendToAllUsersViaTopic(
    String title,
    String body,
    String priority,
  ) async {
    try {
      print('DEBUG: Sending via Cloud Function topic broadcast (eliminates duplicates)');
      
      // Use ONLY the Cloud Function topic broadcast
      // This reuses the same infrastructure as daily Krishna reminders
      final topicSuccess = await FCMPushService.sendPushNotificationToTopic(
        topic: 'daily_krishna_reminders',
        title: title,
        body: body,
        priority: priority,
        data: {
          'type': 'admin_broadcast',
          'targetAudience': 'All Users',
        },
      );

      // Get user count for statistics only (don't send individual notifications)
      final allUsers = await _getTargetUsers('All Users');
      final userCount = allUsers.length;

      // Store broadcast record in Firestore for analytics
      await FirebaseFirestore.instance
          .collection('notification_broadcasts')
          .add({
        'title': title,
        'body': body,
        'priority': priority,
        'targetAudience': 'All Users',
        'status': topicSuccess ? 'sent' : 'failed',
        'createdAt': FieldValue.serverTimestamp(),
        'method': 'cloud_function_topic',
        'topicSuccess': topicSuccess,
        'totalTargeted': userCount,
      });
      
      print('DEBUG: Cloud Function topic broadcast: $topicSuccess, Target count: $userCount');
      return topicSuccess;
      
    } catch (e) {
      print('ERROR sending via Cloud Function broadcast: $e');
      return false;
    }
  }
}