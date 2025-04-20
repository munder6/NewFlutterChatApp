import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart'; // استيراد حزمة لوتي
import '../controller/onboarding_controller.dart';
import '../routers.dart';

class OnboardingScreen extends StatefulWidget {
  OnboardingScreen({super.key});

  final box = GetStorage(); // الوصول إلى التخزين المحلي

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingController controller = Get.put(OnboardingController());

  final List<String> titles = [
    "Fast and Impressive Performance",
    "Guaranteed Security",
    "Unlimited Messages",
    "Encrypted Voice Calls Support",
  ];

  final List<String> descriptions = [
    'Our app is designed to work at high speed, ensuring a smooth and delay-free user experience.\n Whether you’re browsing messages or making voice calls, you’ll feel the performance difference.',
    "We take your data security seriously. Every conversation and call is encrypted to protect your\n privacy and ensure no information is leaked.",
    "There are no limits to the number of messages you can send! Stay in touch with your friends and\n family endlessly and enjoy exchanging thoughts and conversations at any time.",
    "Enjoy high-quality and secure voice calls. All calls are fully encrypted to ensure the safety of\n your data during conversations."
  ];

  final List<String> animation = [
    "assets/lottie/splash.json",
    "assets/lottie/splash.json",
    "assets/lottie/splash.json",
    "assets/lottie/splash.json"
  ];

  @override
  Widget build(BuildContext context) {
    // التحقق من الوضع، سواء كان Dark Mode أو Light Mode
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white, // تغيير خلفية الشاشة بناءً على الوضع
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.updatePageIndex,
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // إضافة صورة لوتي هنا فوق النص
                    Lottie.asset(
                      animation[index], // تعيين مسار لوتي المخصص
                      width: 200, // تعيين عرض الصورة
                      height: 200, // تعيين ارتفاع الصورة
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Text(
                        titles[index],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black, // لون النص بناءً على الوضع
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Text(
                        descriptions[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black87, // لون النص بناءً على الوضع
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: controller.pageIndex.value == index
                      ? (isDarkMode ? Colors.blueAccent : Colors.blue) // تغيير اللون بناءً على الوضع
                      : (isDarkMode ? Colors.grey : Colors.grey[400]),
                ),
              );
            }),
          )),
          SizedBox(height: 20),
          Obx(() => Padding(
            padding: const EdgeInsets.all(40.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.black, // تغيير لون الزر بناءً على الوضع
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: EdgeInsets.symmetric(vertical: 14),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                if (controller.pageIndex.value == 3) {
                  widget.box.write('onboarding_completed', true); // تحديث حالة الاونبوردينغ
                  Get.offAllNamed(AppRoutes.login); // توجيه المستخدم لصفحة اللوقين
                } else {
                  controller.nextPage(); // الانتقال إلى الصفحة التالية
                }
              },
              child: Text(
                controller.pageIndex.value == 3 ? "Get Started" : "Next",
                style: TextStyle(color: isDarkMode ? Colors.black : Colors.white), // تغيير لون النص بناءً على الوضع
              ),
            ),
          )),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
