import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditProfileController extends GetxController {
  var fullName = ''.obs;
  var username = ''.obs;
  var profileImageUrl = ''.obs;
  var isUploadingImage = false.obs; // متغير متابعة الرفع

  final box = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fullName.value = box.read('fullName') ?? '';
    username.value = box.read('username') ?? '';
    profileImageUrl.value = box.read('profileImageUrl') ?? '';
  }

  Future<void> updateFullName(String newFullName) async {
    fullName.value = newFullName;
    box.write('fullName', newFullName);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));

    await userRef.update({'fullName': newFullName});

    Get.snackbar(
      "Name Updated",
      "Your full name has been updated successfully.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  Future<void> updateUsername(String newUsername) async {
    var snapshot = await _firestore.collection('users')
        .where('username', isEqualTo: newUsername)
        .get();

    if (snapshot.docs.isNotEmpty) {
      Get.snackbar(
        "Username Taken",
        "This username is already taken, please choose another one.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return;
    }

    username.value = newUsername;
    box.write('username', newUsername);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));
    await userRef.update({'username': newUsername});

    Get.snackbar(
      "Username Updated",
      "Your username has been updated successfully.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // ✅ أهم جزء: تحديث صورة البروفايل مع الضغط والرفع مثل الستوري بالضبط
  Future<void> updateProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    isUploadingImage.value = true;

    try {
      print('🔼 رفع صورة البروفايل');
      print("📁 الصورة الأصلية: ${pickedFile.path}");
      print("📏 الحجم الأصلي: ${await File(pickedFile.path).length()} bytes");

      // ✅ نضغط الصورة
      File compressedFile = await _compressFile(File(pickedFile.path));
      print("📦 الحجم بعد الضغط: ${await compressedFile.length()} bytes");

      String fileName = 'profile_images/${box.read('user_id')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);

      UploadTask uploadTask = ref.putFile(compressedFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📤 رفع قيد التنفيذ: ${progress.toStringAsFixed(2)}%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      profileImageUrl.value = downloadUrl;
      box.write('profileImageUrl', downloadUrl);

      var userRef = _firestore.collection('users').doc(box.read('user_id'));
      await userRef.update({
        'profileImageUrl': downloadUrl,
        'profileImage': downloadUrl,
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
      print('🔥🔥🔥 ERROR UPDATING PROFILE IMAGE: $e');
      Get.snackbar(
        "Error",
        "There was an error while updating the profile image.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ✅ كود ضغط الصورة
  Future<File> _compressFile(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null) {
      return file;
    }

    final compressedFile = File(targetPath)..writeAsBytesSync(compressedBytes);
    return compressedFile;
  }
}
