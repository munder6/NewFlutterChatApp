import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // ✅ إضافة الاستيراد


class StoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final picker = ImagePicker();

  var isUploading = false.obs;

  // ✅ Pick image or video
  Future<XFile?> pickMedia({required bool isVideo}) async {
    return await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
  }

  // ✅ Upload media and create story
  Future<void> uploadStory({
    required String userId,
    required XFile file,
    required bool isVideo,
  }) async {
    isUploading.value = true;
    try {
      print('🔼 رفع ستوري للمستخدم: $userId');
      print("📁 الصورة الأصلية: ${file.path}");
      print("📏 الحجم الأصلي: ${await File(file.path).length()} bytes");

      final ext = file.path.split('.').last;
      final ref = _storage
          .ref()
          .child('stories/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext');

      final metadata = SettableMetadata(
        contentType: isVideo ? 'video/mp4' : 'image/png',
      );

      // ✅ ضغط الصورة قبل الرفع
      File compressedFile = await _compressFile(File(file.path));
      print("📦 الحجم بعد الضغط: ${await compressedFile.length()} bytes");

      final uploadTask = ref.putFile(compressedFile, metadata);

      // ✅ طباعة نسبة التقدم
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📤 رفع قيد التنفيذ: ${progress.toStringAsFixed(2)}%');
      });

      final mediaUrl = await uploadTask.then((task) => task.ref.getDownloadURL());
      print('✅ الرابط النهائي: $mediaUrl');

      int duration = isVideo
          ? await _getVideoDurationInSeconds(file.path)
          : 10;

      if (isVideo && duration > 15) {
        throw Exception("الفيديو أطول من 15 ثانية، غير مسموح رفعه.");
      }

      final story = StoryModel(
        storyId: '',
        mediaUrl: mediaUrl,
        mediaType: isVideo ? 'video' : 'image',
        createdAt: DateTime.now(),
        expireAt: DateTime.now().add(Duration(hours: 24)),
        duration: duration,
        viewedBy: [],
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .add(story.toMap());

      print('✅ الستوري انرفعت وتم حفظها في Firestore!');
      Get.back();
    } catch (e) {
      print('🔥🔥🔥 ERROR UPLOADING: $e');
      rethrow;
    } finally {
      isUploading.value = false;
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
      return file; // إذا فشل الضغط يرجع الملف الأصلي
    }

    final compressedFile = File(targetPath)..writeAsBytesSync(compressedBytes);

    return compressedFile;
  }


  // ✅ Get all stories of a user
  Stream<List<StoryModel>> getUserStories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('stories')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => StoryModel.fromMap(doc.data(), doc.id)).toList());
  }

  // ✅ Add viewer to story
  Future<void> markStoryAsViewed(String ownerId, String storyId, String viewerId) async {
    final ref = _firestore.collection('users').doc(ownerId).collection('stories').doc(storyId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final viewedBy = List<String>.from(doc['viewedBy'] ?? []);
    if (!viewedBy.contains(viewerId)) {
      viewedBy.add(viewerId);
      await ref.update({'viewedBy': viewedBy});
    }


  }


  // ✅ Get video duration helper
  Future<int> _getVideoDurationInSeconds(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    final duration = controller.value.duration.inSeconds;
    await controller.dispose();
    return duration;
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Error fetching user info: $e');
      return null;
    }
  }
}


