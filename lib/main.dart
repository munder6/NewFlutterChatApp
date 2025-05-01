import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:meassagesapp/app_theme.dart';
import 'package:meassagesapp/routers.dart';
import 'controller/auth_controller.dart';
import 'controller/chat_controller.dart';
import 'controller/user_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await GetStorage.init();
  Get.put(AuthController()); // تسجيل الكونترولر في GetX
  Get.put(UserController()); // 👈 أضف هذا السطر
  Get.put(ChatController()); // ✅ هنا
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final box = GetStorage(); // إنشاء كائن GetStorage
  bool? isDarkMode;

  @override
  void initState() {
    super.initState();
    _setInitialDarkMode(); // تعيين الوضع الافتراضي بناءً على إعدادات النظام
    // الاستماع لتغييرات الوضع (Dark/Light) بشكل لحظي
    _updateSystemUI(isDarkMode);  // تحديث الـ StatusBar والـ NavigationBar بناءً على الوضع

    WidgetsBinding.instance.window.onPlatformBrightnessChanged = _onBrightnessChanged;
  }

  // الدالة للكشف عن الوضع الافتراضي وحفظه في GetStorage
  void _setInitialDarkMode() {
    // إذا كانت القيمة غير موجودة في GetStorage
    if (box.read('darkMode') == null) {
      bool systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      box.write('darkMode', systemDarkMode); // حفظ الوضع في GetStorage
      isDarkMode = systemDarkMode;
    } else {
      isDarkMode = box.read('darkMode') ?? false;
    }
  }

  // الدالة التي يتم استدعاؤها عند تغيير وضع النظام بين الداكن والفاتح
  void _onBrightnessChanged() {
    bool systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    if (systemDarkMode != isDarkMode) {
      setState(() {
        isDarkMode = systemDarkMode; // تحديث الوضع بناءً على إعدادات النظام
        box.write('darkMode', isDarkMode); // حفظ الوضع الجديد في GetStorage
      });
    }
  }

  // تحديث الـ StatusBar و الـ NavigationBar بناءً على الوضع
  void _updateSystemUI(bool? isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: isDarkMode == true ? Colors.black : Colors.white, // لون شريط الحالة
      statusBarIconBrightness: isDarkMode == true ? Brightness.light : Brightness.dark, // لون أيقونات شريط الحالة
      systemNavigationBarColor: isDarkMode == true ? Colors.black : Colors.white, // لون شريط الإيماءات
      systemNavigationBarIconBrightness: isDarkMode == true ? Brightness.light : Brightness.dark, // لون الأيقونات في شريط الإيماءات
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme, // Light Theme
      darkTheme: AppTheme.darkTheme, // Dark Theme
      themeMode: isDarkMode == true ? ThemeMode.dark : ThemeMode.light, // استخدام الوضع الداكن أو الفاتح بناءً على GetStorage
      initialRoute: AppRoutes.splash, // تحديد البداية
      getPages: AppRoutes.routes,
    );
  }
}
