// Simple Node.js Cloud Function for daily Krishna notifications
// This would run on Firebase Functions or any server

const admin = require('firebase-admin');
admin.initializeApp();

// Function to send daily Krishna reminders
exports.sendDailyKrishnaReminders = async (req, res) => {
  try {
    const message = {
      notification: {
        title: 'Hare Krishna! 🙏',
        body: 'Start your day with Krishna consciousness'
      },
      topic: 'daily_krishna_reminders'
    };

    const response = await admin.messaging().send(message);
    console.log('Daily notification sent:', response);
    
    res.status(200).json({
      success: true,
      messageId: response
    });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Schedule this function to run daily at 10:07 PM IST
// Using cron job or Firebase Pub/Sub scheduler:
// "7 22 * * *" for 10:07 PM daily

exports.scheduledDailyReminder = async (context) => {
  console.log('Scheduled function triggered at:', new Date().toISOString());
  
  try {
    const message = {
      notification: {
        title: 'Hare Krishna! 🙏',
        body: 'Start your day with Krishna consciousness'
      },
      topic: 'daily_krishna_reminders',
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'krishna_reminders'
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('Scheduled daily notification sent:', response);
    
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error in scheduled notification:', error);
    throw error;
  }
};