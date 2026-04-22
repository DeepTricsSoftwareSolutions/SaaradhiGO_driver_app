import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Must be called to configure firebase with google-services.json
      await Firebase.initializeApp();
      
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission (Apple & Web)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Get APN/FCM token
      final token = await messaging.getToken();
      debugPrint('FCM Registration Token: $token');

      // Initialize background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle message events when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          // Note: FlutterLocalNotificationsPlugin could be used here to pop a foreground tray notification
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("=================================================================");
      debugPrint("FIREBASE CRITICAL FAILURE: \$e");
      debugPrint("Have you placed the google-services.json in android/app/ ??");
      debugPrint("=================================================================");
    }
  }
}
