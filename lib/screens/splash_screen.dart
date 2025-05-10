import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routers.dart';

class SplashScreen extends StatelessWidget {
  final box = GetStorage();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 2), () async {
        bool isLoggedIn = box.read('is_logged_in') ?? false;
        bool isOnboardingCompleted = box.read('onboarding_completed') ?? false;
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (isLoggedIn && currentUser != null) {
          await currentUser.reload(); // تحديث الحالة
          if (currentUser.emailVerified) {
            return AppRoutes.main;
          } else {
            return AppRoutes.verifyemail;
          }
        } else if (isOnboardingCompleted) {
          return AppRoutes.login;
        } else {
          return AppRoutes.onboarding;
        }
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Lottie.asset(
                "assets/lottie/splash.json",
                height: 60,
              ),
            ),
          );
        } else {
          String nextRoute = snapshot.data as String;
          Future.microtask(() => Get.offAllNamed(nextRoute));
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Lottie.asset(
                "assets/lottie/splash.json",
                height: 60,
              ),
            ),
          );
        }
      },
    );
  }
}
