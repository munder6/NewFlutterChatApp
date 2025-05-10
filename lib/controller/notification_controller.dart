import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationController {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    // طلب الإذن من المستخدم
    await _fcm.requestPermission();

    // إعداد القناة (Android فقط)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(settings);

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // الاستماع للإشعارات أثناء تشغيل التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
    });
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: android.smallIcon,
          ),
        ),
      );
    }
  }

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final data = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'priority': 'high',
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_FIREBASE_SERVER_KEY',
      };

      final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final response = await HttpClient()
          .postUrl(uri)
          .then((HttpClientRequest request) async {
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Authorization', headers['Authorization']!);
        request.add(utf8.encode(json.encode(data)));
        return await request.close();
      });

      if (response.statusCode != 200) {
        print('❌ Failed to send push notification. Status: ${response.statusCode}');
      } else {
        print('✅ Push notification sent successfully.');
      }
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }
}
