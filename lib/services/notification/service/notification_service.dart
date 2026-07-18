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

  bool _initialized = false;

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
    if (!_initialized) {
      await _requestPermission();
      await _initLocalNotifications();
      _listenForegroundMessages();
      _listenTokenRefresh();
      _listenNotificationTaps();
      _initialized = true;
    }

    await _saveTokenToFirestore();
  }

  Future<void> detachToken(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } on FirebaseException catch (e) {
      debugPrint('Failed to detach FCM token: ${e.code}');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission();
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_stat_notification');
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
              icon: 'ic_stat_notification',
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
      debugPrint('FCM token refreshed');
      await _updateTokenInFirestore(newToken);
    });
  }

  void _listenNotificationTaps() {
    // App was backgrounded, user tapped the notification to return
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened app: ${message.messageId}');
      _handleNotificationTap(message.data['type'] as String?);
    });

    // App was fully terminated, user tapped notification to launch it
    unawaited(
      _fcm.getInitialMessage().then((message) {
        if (message != null) {
          debugPrint('App launched from notification: ${message.messageId}');
          _handleNotificationTap(message.data['type'] as String?);
        }
      }),
    );
  }

  Future<void> _saveTokenToFirestore() async {
    final token = await _fcm.getToken();
    debugPrint('FCM token retrieved: ${token != null}');
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
}
