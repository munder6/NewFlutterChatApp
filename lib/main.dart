import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_theme.dart';
import 'routers.dart';
import 'firebase_options.dart';
import 'controller/auth_controller.dart';
import 'controller/chat_controller.dart';
import 'controller/user_controller.dart';
import 'controller/notification_controller.dart';
import 'services/audio_player_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background Notification Received: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await GetStorage.init();
  Get.put(AudioPlayerService());
  Get.put(NotificationController());
  Get.put(AuthController());
  Get.put(UserController());
  Get.put(ChatController());

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final box = GetStorage();
  bool? isDarkMode;

  @override
  void initState() {
    super.initState();
    _setInitialDarkMode();
    _updateSystemUI(isDarkMode);
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = _onBrightnessChanged;
    _requestNotificationPermissionIfNeeded();
    _listenToForegroundNotifications();
  }

  void _requestNotificationPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  void _listenToForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Channel',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  void _setInitialDarkMode() {
    if (box.read('darkMode') == null) {
      bool systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      box.write('darkMode', systemDarkMode);
      isDarkMode = systemDarkMode;
    } else {
      isDarkMode = box.read('darkMode') ?? false;
    }
  }

  void _onBrightnessChanged() {
    bool systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    if (systemDarkMode != isDarkMode) {
      setState(() {
        isDarkMode = systemDarkMode;
        box.write('darkMode', isDarkMode);
      });
    }
  }

  void _updateSystemUI(bool? isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: isDarkMode == true ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDarkMode == true ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness: isDarkMode == true ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Messages App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode == true ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
    );
  }
}
