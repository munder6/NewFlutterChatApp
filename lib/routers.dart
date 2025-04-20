import 'package:get/get.dart';
import 'package:meassagesapp/screens/home_screen.dart';
import 'package:meassagesapp/screens/otp_verfiy.dart';
import 'package:meassagesapp/screens/settings_screen.dart';
import 'package:meassagesapp/screens/signup_screen.dart';
import 'package:meassagesapp/screens/verify_email_screen.dart';
import 'package:meassagesapp/screens/main_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onborading_screen.dart';
import '../screens/splash_screen.dart';
import 'controller/auth_controller.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String chat = '/chat';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String main = '/main';
  static const String verify = '/verify';
  static const String verifyemail = '/verify-email';
  static const String settings = '/settings';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: onboarding, page: () => OnboardingScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: signup, page: () => SignupScreen()),
    GetPage(name: verify, page: () => OtpScreen()),
    GetPage(name: verifyemail, page: () => VerifyEmailScreen()),
    GetPage(name: settings, page: () => SettingsScreen()),
    GetPage(name: main, page: () => MainScreen()),
    GetPage(
      name: home,
      page: () => HomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
  ];
}
