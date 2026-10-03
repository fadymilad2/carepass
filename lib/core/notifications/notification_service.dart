import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../router/app_router.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

// ✅ Channel — must match AndroidManifest + Cloud Function
// ⚠️ التعديل هنا: شلنا كلمة description: عشان الإصدار القديم
const _androidChannel = AndroidNotificationChannel(
  'carepass_notifications',
  'CarePass Notifications',
  description: 'Receive updates about your CarePass subscription and health',
  importance: Importance.high,
);

const String _broadcastTopic = 'all_users';

// ─────────────────────────────────────────────
//  Background FCM Handler
// ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background → system shows notification automatically
}

// ─────────────────────────────────────────────
//  Init Local Notifications
// ─────────────────────────────────────────────
Future<void> initializeLocalNotifications() async {
  const androidInit = AndroidInitializationSettings(
    '@drawable/ic_notification',
  );
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );
  try {
    await localNotifications.initialize(
      settings: initSettings,
      // Updated callback name for newer flutter_local_notifications
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        AppRouter.router.push(AppRoutes.notifications);
      },
    );

    // ✅ Create channel on Android 8+
    final androidImpl = localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(_androidChannel);
    final granted = await androidImpl?.requestNotificationsPermission();
    debugPrint('📱 Notification permission granted: $granted');
  } catch (e) {
    debugPrint('⚠️ Local notifications init failed: $e');
  }
}

// ─────────────────────────────────────────────
//  Show System Notification (foreground)
// ─────────────────────────────────────────────
Future<void> _showSystemNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  // ⚠️ التعديل هنا: نسقنا مع الباراميتر المخصص للوصف في الإصدار الجديد
  const androidDetails = AndroidNotificationDetails(
    'carepass_notifications', // ✅ must match channel + AndroidManifest
    'CarePass Notifications',
    color: Color(0xFF0D7B6E),
    channelDescription: 'Receive updates about your CarePass subscription',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_notification', // ✅ must match the icon in AndroidManifest
    showWhen: true,
    enableVibration: true,
  );

  try {
    await localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
    debugPrint('✅ Foreground notification shown: ${notification.title}');
  } catch (e, st) {
    debugPrint('❌ Failed to show foreground notification: $e');
    debugPrint('$st');
  }
}

class NotificationService {
  bool _disposed = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void> start() async {
    try {
      await _start();
    } catch (e) {
      debugPrint('Notification setup failed: $e');
    }
  }

  Future<void> _start() async {
    final messaging = FirebaseMessaging.instance;

    // ✅ Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // iOS foreground
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    try {
      await messaging.subscribeToTopic(_broadcastTopic);
      debugPrint('✅ Subscribed to topic: $_broadcastTopic');
    } catch (e) {
      debugPrint('⚠️ Failed to subscribe to $_broadcastTopic: $e');
    }
    if (_disposed) return;
    // ✅ Save FCM token when user logs in
    _subscriptions.add(
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _saveCurrentToken(user.uid);
        }
      }),
    );

    // ✅ Token refresh
    _subscriptions.add(
      messaging.onTokenRefresh.listen((token) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) _saveFcmToken(uid, token);
      }),
    );

    // ✅ FOREGROUND — Show as SYSTEM notification in notification bar + SnackBar
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) async {
        // 1. Show in system notification bar ✅
        await _showSystemNotification(message);

        // 2. Also show SnackBar inside app for quick visibility (using Safe Global Key)
      }),
    );

    // ✅ Background → open notification page when tapped
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppRouter.router.push(AppRoutes.notifications);
      }),
    );

    // ✅ Terminated → open notification page
    final initial = await messaging.getInitialMessage();
    if (initial != null && !_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) AppRouter.router.push(AppRoutes.notifications);
      });
    }
  }

  Future<void> _saveFcmToken(String uid, String token) async {
    try {
      if (_disposed || FirebaseAuth.instance.currentUser?.uid != uid) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _saveCurrentToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveFcmToken(uid, token);
    } catch (e) {
      debugPrint('Token retrieval failed: $e');
    }
  }

  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}
