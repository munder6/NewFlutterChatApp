// 🔥 AUTH CONTROLLER كامل بعد التعديل 🔥
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  void _checkLoginStatus() async {
    bool isLoggedIn = box.read('is_logged_in') ?? false;
    User? currentUser = _auth.currentUser;

    if (isLoggedIn && currentUser != null) {
      await currentUser.reload();
      if (currentUser.emailVerified) {
        Get.offAllNamed('/main');
      } else {
        await _auth.signOut();
        box.erase();
        Get.offAllNamed('/verify-email');
      }
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

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.reload();
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        Get.offAllNamed('/verify-email');
        return;
      }

      await _setUserLoggedIn();
      await _updateOnlineStatus(true);
      Get.offAllNamed('/main');
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
      // تحديث حالة الأونلاين في Realtime Database
      DatabaseReference ref = FirebaseDatabase.instance.ref("status/$uid");
      await ref.set({
        "isOnline": false,
        "lastSeen": ServerValue.timestamp,
      });

      // ✅ إزالة fcmToken الخاص بالجهاز الحالي فقط
      if (Platform.isAndroid) {
        String? currentFcmToken = await FirebaseMessaging.instance.getToken();
        if (currentFcmToken != null) {
          DocumentReference userRef = _firestore.collection('users').doc(uid);
          await userRef.update({
            'fcmTokens': FieldValue.arrayRemove([currentFcmToken])
          });
        }
      }
    }

    // تسجيل الخروج من Firebase وتهيئة التطبيق من جديد
    await _auth.signOut();
    box.erase();
    Get.offAllNamed('/onboarding');
  }

  // ✅ تخزين معلومات اليوزر عند تسجيل الدخول
  Future<void> _setUserLoggedIn() async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      DocumentReference userRef = _firestore.collection("users").doc(uid);
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        box.write('user_id', uid);
        box.write('fullName', userData['fullName']);
        box.write('username', userData['username']);
        box.write('email', userData['email']);
        box.write('is_logged_in', true);

        // ✅ bio
        box.write('bio', userData['bio'] ?? '');

        // ✅ birthDate
        if (userData['birthDate'] is Timestamp) {
          box.write('birthDate', (userData['birthDate'] as Timestamp).toDate().toIso8601String());
        } else if (userData['birthDate'] is String) {
          box.write('birthDate', userData['birthDate']);
        } else {
          box.write('birthDate', null);
        }

        String? profileImageUrl = userData['profileImageUrl'] ?? userData['profileImage'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          box.write('profileImageUrl', profileImageUrl);
        } else {
          box.write('profileImageUrl', 'https://i.pravatar.cc/150');
        }

        // ✅ تحديث fcmToken
        if (Platform.isAndroid) {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            List<String> tokens = List<String>.from(userData['fcmTokens'] ?? []);
            if (!tokens.contains(fcmToken)) {
              tokens.add(fcmToken);
              await userRef.update({'fcmTokens': tokens});
            }
          }
        }
      }
    }
  }
}
