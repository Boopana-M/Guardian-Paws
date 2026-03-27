import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase not configured, skip Firebase-related initialization
      print('Firebase not configured: $e');
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localPlugin.initialize(initSettings);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) {
        await _registerInstallation(token);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _showLocal(notification.title ?? 'Guardian-Paws',
              notification.body ?? '');
        }
      });
    } catch (e) {
      print('Firebase messaging setup failed: $e');
    }
  }

  static Future<void> _registerInstallation(String token) async {
    final installation = await ParseInstallation.currentInstallation();
    installation.set('deviceToken', token);
    installation.set('deviceType', Platform.isAndroid ? 'android' : 'ios');
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      installation.set('user', user.toPointer());
    }
    await installation.save();
  }

  static Future<void> _showLocal(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'guardian_paws_channel',
      'Guardian-Paws Alerts',
      channelDescription: 'Safety alerts and protection mode events',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localPlugin.show(0, title, body, details);
  }

  static Future<void> showProtectionCheckPrompt() async {
    await _showLocal(
      'Guardian-Paws',
      'Time to greet your Guardian cat.',
    );
  }
}

