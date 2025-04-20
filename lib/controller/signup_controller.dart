import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage box = GetStorage();
  var isLoading = false.obs;

  // 🔹 تسجيل مستخدم جديد بالبريد الإلكتروني
  Future<void> signUpWithEmail(
      String email, String fullName, String username, String password, String confirmPassword) async {
    if (password != confirmPassword) {
      Get.snackbar("خطأ", "كلمات المرور غير متطابقة");
      return;
    }

    try {
      isLoading.value = true;
      if (await isUserDataTaken(email, username)) return;

      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // ✅ استخدام الرابط الثابت للصورة الشخصية
      String avatarUrl = "https://k.top4top.io/p_3330owv2f1.png"; // الرابط الافتراضي

      // ✅ حفظ بيانات المستخدم بعد التسجيل
      await _saveUserData(userCredential.user!, fullName, username, email, avatarUrl);

      // 🔹 إرسال تأكيد البريد الإلكتروني
      await userCredential.user!.sendEmailVerification();

      // 🔹 توجيه المستخدم لصفحة تأكيد البريد
      Get.offAllNamed('/verify-email');
    } catch (e) {
      Get.snackbar("خطأ", "فشل إنشاء الحساب: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 تسجيل حساب جديد عبر Google
  Future<void> signUpWithGoogle() async {
    try {
      isLoading.value = true;
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      String email = userCredential.user!.email ?? "";
      String displayName = userCredential.user!.displayName ?? "";
      String username = email.split('@')[0];

      if (await isUserDataTaken(email, username)) return;

      // ✅ استخدام الرابط الثابت للصورة الشخصية
      String avatarUrl = "https://k.top4top.io/p_3330owv2f1.png"; // الرابط الافتراضي

      await _saveUserData(userCredential.user!, displayName, username, email, avatarUrl);

      Get.offAllNamed('/main');
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الحساب عبر Google: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 التحقق من تكرار البيانات
  Future<bool> isUserDataTaken(String email, String username) async {
    var users = _firestore.collection('users');

    var emailQuery = await users.where('email', isEqualTo: email).get();
    if (emailQuery.docs.isNotEmpty) {
      Get.snackbar("خطأ", "البريد الإلكتروني مستخدم بالفعل");
      return true;
    }

    var usernameQuery = await users.where('username', isEqualTo: username).get();
    if (usernameQuery.docs.isNotEmpty) {
      Get.snackbar("خطأ", "اسم المستخدم مأخوذ");
      return true;
    }

    return false;
  }

  // 🔹 حفظ بيانات المستخدم في Firestore
  Future<void> _saveUserData(User user, String fullName, String username, String email, String avatarUrl) async {
    String uid = user.uid;

    await _firestore.collection("users").doc(uid).set({
      "uid": uid,
      "fullName": fullName,
      "username": username,
      "email": email,
      "createdAt": DateTime.now(),
      "profileImage": avatarUrl,
      "isOnline": true, // ✅ المستخدم دخل التطبيق الآن
      "lastSeen": FieldValue.serverTimestamp(),
      "showOnlineStatus": true,
      "isTyping": false, // ✅ مبدئياً مش بيكتب
    });

    // تخزين محلي
    box.write('user_id', uid);
    box.write('fullName', fullName);
    box.write('username', username);
    box.write('email', email);
    box.write('profileImage', avatarUrl);
    box.write('is_logged_in', true);
  }
}
