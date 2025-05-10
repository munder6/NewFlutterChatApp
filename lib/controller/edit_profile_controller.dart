import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfileController extends GetxController {
  var fullName = ''.obs;
  var username = ''.obs;
  var profileImageUrl = ''.obs;
  var bio = ''.obs;
  var birthDate = ''.obs;
  var isUploadingImage = false.obs;

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
    bio.value = box.read('bio') ?? '';
    birthDate.value = box.read('birthDate') ?? '';
  }

  Future<void> updateFullName(String newFullName) async {
    fullName.value = newFullName;
    box.write('fullName', newFullName);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));

    await userRef.update({'fullName': newFullName});

    Get.snackbar(
      "",
      "",
      titleText: Text(
        "Name Updated",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
      ),
      messageText: Text(
        "Your full name has been updated successfully.",
        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
      ),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Colors.green.withOpacity(0.1),
      borderRadius: 8,
      maxWidth: 400,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      "",
      "",
      titleText: Text(
        "Username Updated",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
      ),
      messageText: Text(
        "Your username has been updated successfully.",
        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
      ),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Colors.green.withOpacity(0.1),
      borderRadius: 8,
      maxWidth: 400,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: Duration(seconds: 3),
    );

  }

  Future<void> updateBio(String newBio) async {
    bio.value = newBio;
    box.write('bio', newBio);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));
    await userRef.update({'bio': newBio});

    Get.snackbar(
      "",
      "",
      titleText: Text(
        "Bio Updated",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
      ),
      messageText: Text(
        "Your bio has been updated successfully.",
        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
      ),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Colors.green.withOpacity(0.1),
      borderRadius: 8,
      maxWidth: 400,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: Duration(seconds: 3),
    );

  }

  Future<void> updateBirthDate(String newBirthDate) async {
    birthDate.value = newBirthDate;
    box.write('birthDate', newBirthDate);

    var userRef = _firestore.collection('users').doc(box.read('user_id'));
    await userRef.update({'birthDate': newBirthDate});

    Get.snackbar(
      "",
      "",
      titleText: Text(
        "Birth Date Updated",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
      ),
      messageText: Text(
        "Your birth date has been updated successfully.",
        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
      ),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Colors.green.withOpacity(0.1),
      borderRadius: 8,
      maxWidth: 400,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: Duration(seconds: 3),
    );

  }

  Future<void> updateProfileImage() async {
    final PermissionStatus status = await Permission.photos.status;
    if (!status.isGranted) {
      final PermissionStatus result = await Permission.photos.request();
      if (!result.isGranted) {
        Get.snackbar("رفض الإذن", "يرجى منح صلاحية الوصول للمتابعة.");
        return;
      }
    }

    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File originalFile = File(pickedFile.path);

    // ✂️ قص الصورة باستخدام ImageCropper
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: originalFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // ✅ مربع دائمًا

      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'تعديل الصورة',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'تعديل الصورة',
        ),
      ],
    );

    if (cropped == null) {
      Get.snackbar("إلغاء", "لم يتم قص الصورة.");
      return;
    }

    originalFile = File(cropped.path); // 🔁 استخدم الصورة المقصوصة

    isUploadingImage.value = true;

    try {
      print('🔼 رفع صورة البروفايل');
      print("📁 الصورة الأصلية: ${originalFile.path}");
      print("📏 الحجم الأصلي: ${await originalFile.length()} bytes");

      File compressedFile = await _compressFile(originalFile);
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
        "",
        "",
        titleText: Text(
          "تم تحديث الصورة الشخصية",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
        ),
        messageText: Text(
          "تم تحديث صورتك الشخصية بنجاح.",
          style: TextStyle(fontSize: 13, color: Colors.green.shade700),
        ),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: Colors.green.withOpacity(0.1),
        borderRadius: 8,
        maxWidth: 400,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: Duration(seconds: 3),
      );

    } catch (e) {
      print('🔥🔥🔥 ERROR UPDATING PROFILE IMAGE: $e');
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء رفع صورة الملف الشخصي.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

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
