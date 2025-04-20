import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController with WidgetsBindingObserver {  // إضافة المراقب
  static AuthController instance = Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final box = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this); // إضافة المراقب
    firebaseUser.bindStream(_auth.authStateChanges());
    _checkLoginStatus();
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this); // إزالة المراقب عند الإغلاق
  }

  void _checkLoginStatus() {
    bool isLoggedIn = box.read('is_logged_in') ?? false;
    if (isLoggedIn) {
      Get.offAllNamed('/main');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    String? userId = box.read('user_id');
    if (userId != null) {
      if (state == AppLifecycleState.resumed) {
        // عندما يعود التطبيق إلى الواجهة الأمامية
        _updateOnlineStatus(true); // تعيين isOnline إلى true
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        // عندما يذهب التطبيق إلى الخلفية أو يتم سحبه من شاشة التطبيقات
        _updateOnlineStatus(false); // تعيين isOnline إلى false
      }
    }
  }

  // تحديث حالة الـ isOnline
  Future<void> _updateOnlineStatus(bool isOnline) async {
    String uid = box.read('user_id') ?? '';
    if (uid.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
      });
    }
  }

  // 🔹 تسجيل الدخول باستخدام البريد الإلكتروني أو اسم المستخدم
  Future<void> signInWithEmailOrUsername(String emailOrUsername, String password) async {
    try {
      // إذا كان المدخل هو بريد إلكتروني، نستخدمه مباشرة
      if (emailOrUsername.contains("@")) {
        // ✅ تسجيل الدخول باستخدام البريد الإلكتروني مباشرةً
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailOrUsername,
          password: password,
        );

        if (userCredential.user != null) {
          _setUserLoggedIn();
          _updateOnlineStatus(true);  // تعيين `isOnline` إلى true عند تسجيل الدخول
          Get.offAllNamed('/main');
        }
      } else {
        // ✅ البحث عن المستخدم عبر اسم المستخدم
        var userQuery = await _firestore.collection('users').where('username', isEqualTo: emailOrUsername).get();

        if (userQuery.docs.isEmpty) {
          Get.snackbar("خطأ", "اسم المستخدم غير مسجل!");
          return;
        }

        // إذا تم العثور على المستخدم، نقوم بإعادة كلمة المرور الخاصة به
        var userDoc = userQuery.docs.first;
        String email = userDoc['email'];

        // تسجيل الدخول باستخدام البريد الإلكتروني
        await signInWithEmailOrUsername(email, password);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الدخول: ${e.toString()}");
    }
  }

  // 🔹 تسجيل الدخول باستخدام Google (يُسمح فقط لمن لديهم حساب مسجل مسبقًا)
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      // ✅ التحقق مما إذا كان المستخدم لديه حساب مسجل مسبقًا
      bool userExists = await _checkIfUserExists(googleUser.email);
      if (!userExists) {
        Get.snackbar("خطأ", "يجب عليك إنشاء حساب أولًا قبل تسجيل الدخول عبر جوجل");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _setUserLoggedIn();
      _updateOnlineStatus(true);  // تعيين `isOnline` إلى true عند تسجيل الدخول
      Get.offAllNamed('/main');
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الدخول عبر جوجل");
    }
  }

  // 🔹 التحقق من إذا كان المستخدم لديه حساب مسجل مسبقًا
  Future<bool> _checkIfUserExists(String? email) async {
    if (email == null) return false;
    var userDoc = await _firestore.collection('users').where('email', isEqualTo: email).get();
    return userDoc.docs.isNotEmpty;
  }

  // 🔹 تسجيل الخروج
  Future<void> signOut() async {
    String? uid = box.read('user_id');

    // ✅ نحدث الريال تايم قبل تسجيل الخروج
    if (uid != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("status/$uid");
      await ref.set({
        "isOnline": false,
        "lastSeen": ServerValue.timestamp,
      });
    }

    // باقي كود sign out
    await FirebaseAuth.instance.signOut();
    box.erase();
    Get.offAllNamed('/onboarding');
  }

  // 🔹 تخزين بيانات المستخدم في GetStorage
  Future<void> _setUserLoggedIn() async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;

      DocumentSnapshot userDoc = await _firestore.collection("users").doc(uid).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        // ✅ تخزين بيانات المستخدم في التخزين المحلي
        box.write('user_id', uid);
        box.write('fullName', userData['fullName']);
        box.write('username', userData['username']);
        box.write('email', userData['email']);
        box.write('is_logged_in', true);
        String? profileImageUrl = userData['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          // إذا كانت موجودة، نضع الرابط
          box.write('profileImageUrl', profileImageUrl);
        } else {
          // إذا لم تكن موجودة، نضع رابط مؤقت
          box.write('profileImageUrl', 'https://i.pravatar.cc/150');
        }
      }
    }
  }
}
