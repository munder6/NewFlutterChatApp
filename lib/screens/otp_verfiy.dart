import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/otp_controller.dart';

class OtpScreen extends StatelessWidget {
  final OTPController otpController = Get.put(OTPController());
  final TextEditingController otpTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تأكيد رقم الهاتف")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("أدخل رمز OTP المرسل إلى هاتفك", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: otpTextController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "رمز التحقق",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Obx(() {
              return otpController.isLoading.value
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  otpController.verifyOTP(otpTextController.text.trim());
                },
                child: Text("تأكيد"),
              );
            }),
          ],
        ),
      ),
    );
  }
}
