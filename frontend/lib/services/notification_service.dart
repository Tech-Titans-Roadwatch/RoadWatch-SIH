import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging setup on the Flutter side.
/// The backend sends the actual push when a complaint status changes.
///
/// Setup checklist:
/// 1. Add google-services.json to flutter_app/android/app/
/// 2. Follow the firebase_messaging Android setup in its pub.dev README
/// 3. Call NotificationService.init() in main.dart before runApp()
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  /// Call once at app startup.
  static Future<void> init() async {
    // Request permission (iOS requires explicit grant; Android 13+ too)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '[FCM] Foreground message: ${message.notification?.title} — ${message.notification?.body}');
      // TODO: show an in-app snackbar/dialog using a GlobalKey<ScaffoldMessengerState>
    });

    // Handle notification tap when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification tapped: ${message.data}');
      // TODO: navigate to the relevant complaint detail screen
    });
  }

  /// Returns the FCM device token for this installation.
  /// Pass this to the backend when submitting a complaint so it can
  /// send status-update notifications back to this specific device.
  static Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Could not get device token: $e');
      return null;
    }
  }
}
