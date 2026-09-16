import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Call once at app startup in main.dart
  static Future<void> init() async {
    // 1. Request permission (iOS + Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize local notifications plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[LocalNotification] Tapped payload: ${response.payload}');
        // TODO: handle navigation when user taps notification banner
      },
    );

    // 3. Create Android Notification Channel for high-importance popups
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'roadwatch_status_channel',
      'Pothole Status Updates',
      description: 'Tracks submission, verification, assignment, and resolution',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle notifications when app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title} - ${message.notification?.body}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Display a visible local banner when an FCM message arrives
      if (notification != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data['route'],
        );
      }
    });

    // 5. Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification tapped in background: ${message.data}');
    });
  }

  /// Returns the FCM device token for this installation.
  /// Pass this to your FastAPI backend when submitting reports so it can target this device.
  static Future<String?> getDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('[FCM] Device Token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Could not get device token: $e');
      return null;
    }
  }

  /// Helper method to trigger local status updates directly from UI actions
  static Future<void> showLocalStatus({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'roadwatch_status_channel',
      'Pothole Status Updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
