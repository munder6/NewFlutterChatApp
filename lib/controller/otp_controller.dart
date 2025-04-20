import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../routers.dart';

class OTPController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var verificationId = ''.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    verificationId.value = Get.arguments ?? ''; // استلام verificationId عند فتح الصفحة
  }

  // استدعاء هذا عند التنقل لصفحة OTP وتمرير verificationId إليها
  void setVerificationId(String id) {
    verificationId.value = id;
  }

  // التحقق من رمز OTP
  Future<void> verifyOTP(String otp) async {
    try {
      isLoading(true);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      // ✅ بعد نجاح تسجيل الدخول، توجه المستخدم للصفحة الرئيسية
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar("خطأ", "كود OTP غير صحيح أو منتهي الصلاحية");
    } finally {
      isLoading(false);
    }
  }
}
