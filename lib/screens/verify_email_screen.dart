import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VerifyEmailScreen extends StatefulWidget {
  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isVerified = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  // 🔹 التحقق مما إذا كان البريد الإلكتروني قد تم تأكيده
  Future<void> _checkEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    if (user != null && user.emailVerified) {
      setState(() => isVerified = true);
      Get.offAllNamed('/home');
    }
  }

  // 🔹 إعادة إرسال رابط التحقق
  Future<void> _resendVerificationEmail() async {
    try {
      setState(() => isResending = true);
      await _auth.currentUser?.sendEmailVerification();
      Get.snackbar("تم الإرسال", "تم إرسال رابط التحقق مرة أخرى إلى بريدك الإلكتروني.");
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال البريد الإلكتروني: ${e.toString()}");
    } finally {
      setState(() => isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, size: 100, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                "قم بتأكيد بريدك الإلكتروني",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني. يرجى التحقق منه قبل تسجيل الدخول.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkEmailVerified,
                child: Text("تحقق الآن"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              SizedBox(height: 10),
              isResending
                  ? CircularProgressIndicator()
                  : TextButton(
                onPressed: _resendVerificationEmail,
                child: Text("إعادة إرسال البريد الإلكتروني", style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
