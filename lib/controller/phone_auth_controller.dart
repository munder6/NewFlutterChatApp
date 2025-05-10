import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routers.dart';

class PhoneAuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxString phoneNumber = ''.obs;
  String verificationId = '';

  Future<void> verifyPhoneNumber(String phone) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          Get.offAllNamed('/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          Get.snackbar('Error', e.message ?? 'Verification failed');
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          Get.toNamed(AppRoutes.verify);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong. Please try again.');
    }
  }

  Future<void> signInWithCode(String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Error', 'Invalid code or expired. Try again.');
    }
  }
}
