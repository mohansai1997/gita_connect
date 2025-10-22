/**
 * Firebase Cloud Functions for Gita Connect Daily Notifications
 */

const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
initializeApp();

// Set global options for cost control
setGlobalOptions({maxInstances: 10});

/**
 * Scheduled function to send daily Krishna consciousness reminders
 * Runs every day at 10:40 PM IST (22:40)
 */
exports.sendDailyKrishnaReminders = onSchedule({
  schedule: "50 17 * * *", // 10:40 PM daily
  timeZone: "Asia/Kolkata", // IST timezone
  memory: "256MiB",
  maxInstances: 1,
}, async (event) => {
  logger.info("🕰️ Daily Krishna reminder function triggered", {
    timestamp: new Date().toISOString(),
    timezone: "Asia/Kolkata",
  });

  try {
    // Message to send to all subscribers
    const message = {
      notification: {
        title: "Hare Krishna! 🙏",
        body: "Start your day with Krishna consciousness",
      },
      data: {
        type: "daily_reminder",
        timestamp: new Date().toISOString(),
      },
      topic: "daily_krishna_reminders", // Send to all subscribers of this topic
      android: {
        priority: "high",
        notification: {
          channelId: "krishna_reminders",
          sound: "default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            contentAvailable: true,
          },
        },
      },
    };

    // Send the notification
    const response = await getMessaging().send(message);

    logger.info("✅ Daily Krishna reminder sent successfully", {
      messageId: response,
      topic: "daily_krishna_reminders",
    });

    return {
      success: true,
      messageId: response,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("❌ Error sending daily Krishna reminder", {
      error: error.message,
      stack: error.stack,
    });

    throw error;
  }
});

/**
 * HTTP function to manually trigger notification (for testing)
 */
exports.testKrishnaNotification = onRequest({
  cors: true,
  memory: "256MiB",
}, async (req, res) => {
  logger.info("🧪 Manual test notification triggered");

  try {
    const message = {
      notification: {
        title: "Test - Hare Krishna! 🙏",
        body: "This is a test notification from Cloud Functions",
      },
      data: {
        type: "test_notification",
        timestamp: new Date().toISOString(),
      },
      topic: "daily_krishna_reminders",
      android: {
        priority: "high",
        notification: {
          channelId: "krishna_reminders",
          sound: "default",
        },
      },
    };

    const response = await getMessaging().send(message);

    logger.info("✅ Test notification sent successfully", {
      messageId: response,
    });

    res.status(200).json({
      success: true,
      message: "Test notification sent successfully",
      messageId: response,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error("❌ Error sending test notification", {
      error: error.message,
    });

    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * HTTP function for admin to send custom notifications
 * This reuses the same FCM infrastructure as daily reminders
 */
exports.sendAdminNotification = onRequest({
  cors: true,
  memory: "256MiB",
}, async (req, res) => {
  logger.info("📤 Admin notification request received");

  try {
    // Extract notification data from request
    const {title, body, targetAudience = "all"} = req.body;

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: "Title and body are required",
        timestamp: new Date().toISOString(),
      });
    }

    // Create the same message structure as daily reminders
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "admin_notification",
        timestamp: new Date().toISOString(),
        targetAudience: targetAudience,
      },
      topic: "daily_krishna_reminders", // Same topic as daily reminders
      android: {
        priority: "high",
        notification: {
          channelId: "krishna_reminders",
          sound: "default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            contentAvailable: true,
          },
        },
      },
    };

    // Send notification using the same FCM setup
    const response = await getMessaging().send(message);

    logger.info("✅ Admin notification sent successfully", {
      messageId: response,
      title: title,
      targetAudience: targetAudience,
    });

    res.status(200).json({
      success: true,
      message: "Admin notification sent successfully",
      messageId: response,
      title: title,
      targetAudience: targetAudience,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error("❌ Error sending admin notification", {
      error: error.message,
      stack: error.stack,
    });

    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * HTTP function to get notification stats (for monitoring)
 */
exports.getNotificationStats = onRequest({
  cors: true,
  memory: "128MiB",
}, async (req, res) => {
  res.status(200).json({
    service: "Gita Connect Notifications",
    status: "active",
    schedule: "Daily at 22:07 IST",
    topic: "daily_krishna_reminders",
    message: "Hare Krishna! 🙏",
    lastChecked: new Date().toISOString(),
  });
});
