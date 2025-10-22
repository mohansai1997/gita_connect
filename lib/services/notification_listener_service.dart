// Simple stub for NotificationListenerService
// Cloud Functions handle all notifications now

class NotificationListenerService {
  static Future<void> startListening() async {
    print('Cloud Functions handle notifications');
  }
  
  static void stopListening() {
    // No-op since Cloud Functions handle everything
  }
  
  static bool get isListening => true;
}
