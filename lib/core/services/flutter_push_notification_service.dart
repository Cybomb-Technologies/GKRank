import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- TOP-LEVEL HANDLER FOR BACKGROUND MESSAGES (Must be outside the class) ---
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

// ADD THIS TOP-LEVEL FUNCTION
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This runs when the app is in the background or terminated and the user taps a notification.
  if (notificationResponse.payload != null) {
    print('Background notification response handled. Payload: ${notificationResponse.payload}');
    // Add your navigation or logic here
  }
}

// --- Global Instance for Notifications ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// --- Configuration for Android and iOS (for foreground notifications) ---
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _requestPermissions();

    String? fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");

    await _initializeLocalNotifications();

    // Set up handlers for when a message is received
    _setupInteractions();
    _setupMessageHandlers();
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse, // OK for foreground
      // CHANGE THIS LINE: Use the new top-level function
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create the channel on Android 8.0+ devices
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // --- 1. NEW: Define the handler for processing messages from a terminated/background state ---
  void _handleMessage(RemoteMessage message) {
    // This is where you would handle navigation or other logic based on the notification data.
    // For now, we'll just print the data.
    print('Handling message for app launch/open: ${message.data}');
    // You might use a global key here to access the navigator
    // Example: Navigator.of(MyNavigationService.navigatorKey.currentContext!).pushNamed(
    //   '/notification-detail',
    //   arguments: message.data['screen'],
    // );
  }


  // --- 2. Handlers for Notification Clicks/Taps ---
  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    if (notificationResponse.payload != null) {
      print('Notification payload: ${notificationResponse.payload}');
      // You can implement navigation based on the payload data here
    }
  }

  // Handle a notification that was used to open the app from a terminated state.
  void _setupInteractions() {
    // Get any initial message which caused the application to open (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message); // <-- This now calls the defined method
      }
    });

    // Handle messages when the user taps a notification while the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage); // <-- This now calls the defined method
  }

  // --- 3. Handlers for Incoming Messages (Foreground/Background) ---
  void _setupMessageHandlers() {
    // Foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');

        // Show the foreground notification using flutter_local_notifications
        _showLocalNotification(message);
      }
    });
  }

  // --- 4. Show Local Notification for Foreground Messages ---
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
