import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:lottie/lottie.dart';
import '../controller/phone_auth_controller.dart';
import '../app_theme.dart';

class PhoneInputScreen extends StatefulWidget {
  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final PhoneAuthController controller = Get.put(PhoneAuthController());
  final RxBool isValid = true.obs;

  int expectedLength = 9; // default for Palestine
  String formattedHint = '_' * 9;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.asset("assets/lottie/loginanimation.json", height: 180, repeat: false),
              SizedBox(height: 20),
              Text(
                'Phone Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Enter your phone number to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getTextColor(isDarkMode).withOpacity(0.6),
                ),
              ),
              SizedBox(height: 30),
              IntlPhoneField(
                decoration: InputDecoration(
                  hintText: formattedHint,
                  hintStyle: TextStyle(
                    letterSpacing: 2.0,
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                initialCountryCode: 'PS',
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  color: AppTheme.getTextColor(isDarkMode),
                  letterSpacing: 2.0,
                ),
                disableLengthCheck: false,
                onChanged: (phone) {
                  controller.phoneNumber.value = phone.completeNumber;
                  final digitsOnly = phone.number.replaceAll(RegExp(r'[^0-9]'), '');
                  setState(() {
                    final currentLength = digitsOnly.length;
                    final remaining = expectedLength - currentLength;
                    formattedHint = remaining > 0 ? '_' * remaining : '';
                    isValid.value = currentLength >= expectedLength;
                  });
                },
                onCountryChanged: (country) {
                  setState(() {
                    expectedLength = country.maxLength ?? 9;
                    formattedHint = '_' * expectedLength;
                    isValid.value = true;
                  });
                },
              ),
              // Obx(() => isValid.value
              //     ? SizedBox.shrink()
              //     : Padding(
              //   padding: const EdgeInsets.only(top: 8.0, left: 4),
              //   child: Text(
              //     'Invalid phone number format',
              //     style: TextStyle(color: Colors.red, fontSize: 13),
              //   ),
              // )),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (controller.phoneNumber.isNotEmpty && isValid.value) {
                    controller.verifyPhoneNumber(controller.phoneNumber.value);
                  } else {
                    isValid.value = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(isDarkMode),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text("Continue", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
