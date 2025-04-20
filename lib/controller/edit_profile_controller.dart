import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditProfileController extends GetxController {
  var fullName = ''.obs;
  var username = ''.obs;
  var profileImageUrl = ''.obs;
  final box = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات من GetStorage عند فتح الصفحة
    fullName.value = box.read('fullName') ?? '';
    username.value = box.read('username') ?? '';
    profileImageUrl.value = box.read('profileImageUrl') ?? '';
  }

  // دالة للتحقق إذا كان اسم المستخدم موجودًا مسبقًا في Firebase
  Future<bool> isUsernameTaken(String newUsername) async {
    var snapshot = await _firestore.collection('users')
        .where('username', isEqualTo: newUsername)
        .get();

    return snapshot.docs.isNotEmpty; // إذا كانت النتيجة غير فارغة، فهذا يعني أن اسم المستخدم موجود
  }

  // دالة لتحديث البيانات
  Future<void> updateFullName(String newFullName) async {
    fullName.value = newFullName;
    box.write('fullName', newFullName);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));

    await userRef.update({
      'fullName': newFullName,
    });

    Get.snackbar(
      "Name Updated",
      "Your full name has been updated successfully.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // دالة لتحديث اسم المستخدم
  Future<void> updateUsername(String newUsername) async {
    // تحقق من وجود اسم المستخدم
    bool usernameExists = await isUsernameTaken(newUsername);
    if (usernameExists) {
      // في حالة كان اسم المستخدم موجودًا
      Get.snackbar(
        "Username Taken",
        "This username is already taken, please choose another one.",
        snackPosition: SnackPosition.BOTTOM,  // تحديد مكان السناك بار
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return; // لا نستمر في التحديث إذا كان اسم المستخدم موجود
    }

    // إذا لم يكن اسم المستخدم موجودًا
    username.value = newUsername;
    box.write('username', newUsername);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));

    await userRef.update({
      'username': newUsername,
    });

    Get.snackbar(
      "Username Updated",
      "Your username has been updated successfully.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // دالة لاختيار وتحديث الصورة الشخصية
  Future<void> updateProfileImage() async {
    // اختيار الصورة من الكاميرا أو الاستوديو
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // أو ImageSource.camera
    if (image == null) return;

    File file = File(image.path);
    String fileName = 'profile_images/${box.read('user_id')}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      // رفع الصورة إلى Firebase Storage
      UploadTask uploadTask = _storage.ref(fileName).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // تحديث رابط الصورة في Firebase و GetStorage
      profileImageUrl.value = imageUrl;
      box.write('profileImageUrl', imageUrl);

      // تحديث رابط الصورة في Firebase Firestore
      var userRef = _firestore.collection('users').doc(box.read('user_id'));

      await userRef.update({
        'profileImageUrl': imageUrl,
      });
      await userRef.update({
        'profileImage': imageUrl,
      });

      Get.snackbar(
        "Profile Image Updated",
        "Your profile image has been updated successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      print("Error updating profile image: $e");
      Get.snackbar(
        "Error",
        "There was an error while updating the profile image.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }
}
