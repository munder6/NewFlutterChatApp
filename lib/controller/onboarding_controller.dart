import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../screens/login_screen.dart';
// import 'login_screen.dart';

class OnboardingController extends GetxController {
  var pageIndex = 0.obs;
  PageController pageController = PageController();

  void nextPage() {
    if (pageIndex.value < 3) {
      pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.ease);
    } else {
      GetStorage().write('onboarding_done', true); // حفظ أنه تم الانتهاء من Onboarding
      print("recorder done");

      Get.off(LoginScreen()); // الانتقال لصفحة تسجيل الدخول
    }
  }

  void updatePageIndex(int index) {
    pageIndex.value = index;
  }
}


