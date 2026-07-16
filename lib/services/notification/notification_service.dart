import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/ui/routes/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'budget_alerts',
    'Budget Alerts',
    description: 'Energy budget and bill reminders',
    importance: Importance.high,
  );

  void _handleNotificationTap(String? payload) {
    switch (payload) {
      case 'budget_alert':
        unawaited(appRouter.push(AppRoutes.dashboard));
      case 'reading_reminder':
        unawaited(appRouter.push(AppRoutes.addReading));
      default:
        break;
    }
  }

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    _listenForegroundMessages();
    _listenTokenRefresh();
    await _saveTokenToFirestore();
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission();
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _local.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped, payload: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('Foreground message: ${message.messageId}');
      final notification = message.notification;
      if (notification != null) {
        await _local.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: message.data['type'] as String?,
        );
      }
    });
  }

  void _listenTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      await _updateTokenInFirestore(newToken);
    });
  }

  Future<void> _saveTokenToFirestore() async {
    final token = await _fcm.getToken();
    debugPrint('FCM TOKEN: $token');
    if (token != null) {
      await _updateTokenInFirestore(token);
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Call this when app opens from a terminated state via notification tap
  Future<RemoteMessage?> getInitialMessage() => _fcm.getInitialMessage();

  /// Call this to listen for taps while app is backgrounded
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
