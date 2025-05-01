// 🔥 AUTH CONTROLLER كامل بعد التعديل 🔥
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  static AuthController instance = Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final box = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);
    firebaseUser.bindStream(_auth.authStateChanges());
    _checkLoginStatus();
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);
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
        _updateOnlineStatus(true);
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        _updateOnlineStatus(false);
      }
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    String uid = box.read('user_id') ?? '';
    if (uid.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
      });
    }
  }

  // 🔥 تسجيل الدخول بواسطة ايميل أو يوزرنيم 🔥
  Future<void> signInWithEmailOrUsername(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername;

      if (!emailOrUsername.contains("@")) {
        // المستخدم أدخل username → بنبحث عن الايميل المرتبط
        var userQuery = await _firestore.collection('users')
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          Get.snackbar("خطأ", "اسم المستخدم غير مسجل!");
          return;
        }

        email = userQuery.docs.first['email'];
      }

      // تسجيل الدخول بالبريد وكلمة السر
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _setUserLoggedIn();
        await _updateOnlineStatus(true);
        Get.offAllNamed('/main');
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الدخول: ${e.toString()}");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      bool userExists = await _checkIfUserExists(googleUser.email);
      if (!userExists) {
        Get.snackbar("خطأ", "يجب عليك إنشاء حساب أولًا قبل تسجيل الدخول عبر جوجل");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // ✅ هذا هو السطر المهم الذي كنت ناسيه
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ✅ تسجيل الدخول باستخدام الـ credential
      await _auth.signInWithCredential(credential);

      await _setUserLoggedIn();
      await _updateOnlineStatus(true);
      Get.offAllNamed('/main');
    } catch (e) {
      print("Google Sign-In error: $e");
      Get.snackbar("خطأ", "فشل تسجيل الدخول عبر جوجل");
    }
  }

  Future<bool> _checkIfUserExists(String? email) async {
    if (email == null) return false;
    var userDoc = await _firestore.collection('users').where('email', isEqualTo: email).get();
    return userDoc.docs.isNotEmpty;
  }

  Future<void> signOut() async {
    String? uid = box.read('user_id');
    if (uid != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("status/$uid");
      await ref.set({
        "isOnline": false,
        "lastSeen": ServerValue.timestamp,
      });
    }

    await _auth.signOut();
    box.erase();
    Get.offAllNamed('/onboarding');
  }

  // ✅ تخزين معلومات اليوزر عند تسجيل الدخول
  Future<void> _setUserLoggedIn() async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(uid).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        box.write('user_id', uid);
        box.write('fullName', userData['fullName']);
        box.write('username', userData['username']);
        box.write('email', userData['email']);
        box.write('is_logged_in', true);

        String? profileImageUrl = userData['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          box.write('profileImageUrl', profileImageUrl);
        } else {
          box.write('profileImageUrl', 'https://i.pravatar.cc/150');
        }
      }
    }
  }
}
