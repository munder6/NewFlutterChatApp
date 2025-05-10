import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/message_model.dart';
import '../services/video_thumbnail_cache.dart';
import 'notification_controller.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();

  // قائمة الرسائل
  var messages = <MessageModel>[].obs;


  Future<Box<MessageModel>> openChatBox(String chatId) async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    return await Hive.openBox<MessageModel>('chat_$chatId');
  }

  Future<List<MessageModel>> getCachedMessages(String senderId, String receiverId) async {
    final chatBox = await openChatBox(_chatKey(senderId, receiverId));
    return chatBox.values.toList().cast<MessageModel>();
  }

  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) async* {
    final chatBox = await openChatBox(_chatKey(senderId, receiverId));

    yield chatBox.values.toList().cast<MessageModel>();

    yield* _firestore
        .collection('users')
        .doc(senderId)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      final newMessages = snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();

      // تحديث الكاش
      for (var message in newMessages) {
        chatBox.put(message.id, message);
      }

      return newMessages;
    });
  }

  String _chatKey(String senderId, String receiverId) {
    return senderId.compareTo(receiverId) <= 0
        ? '${senderId}_$receiverId'
        : '${receiverId}_$senderId';
  }




  // ✅ إرسال رسالة نصية أو وسائط
  Future<void> sendMessage(
      String senderId,
      String receiverId,
      String content,
      String contentType, {
        String? replyToStoryUrl,
        String? replyToStoryType,
        String? replyToStoryId,
        String? localPath, // ✅ أضف هذا
      }) async {
    try {
      String senderName = box.read('fullName') ?? 'Unknown Sender';
      String senderUsername = box.read('username') ?? 'UnknownUsername';
      String senderImage = box.read('profileImageUrl') ?? '';

      String? receiverName = box.read('receiverName_$receiverId');
      String? receiverUsername = box.read('receiverUsername_$receiverId');
      String? receiverImage = box.read('receiverImage_$receiverId');

      if (receiverName == null || receiverUsername == null || receiverImage == null) {
        DocumentSnapshot receiverDoc =
        await _firestore.collection('users').doc(receiverId).get();
        if (receiverDoc.exists) {
          Map<String, dynamic>? receiverData = receiverDoc.data() as Map<String, dynamic>?;
          receiverName = receiverData?['fullName'] ?? 'Unknown Receiver';
          receiverUsername = receiverData?['username'] ?? 'UnknownUsername';
          receiverImage = receiverData?['profileImageUrl'] ?? '';

          box.write('receiverName_$receiverId', receiverName);
          box.write('receiverUsername_$receiverId', receiverUsername);
          box.write('receiverImage_$receiverId', receiverImage);
        }
      }

      String messageId = _firestore.collection('messages').doc().id;
      final timestamp = Timestamp.now().toDate();

      MessageModel message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        contentType: contentType,
        isRead: false,
        timestamp: timestamp,
        receiverName: receiverName ?? 'Unknown Receiver',
        receiverUsername: receiverUsername ?? 'UnknownUsername',
        replyToStoryUrl: replyToStoryUrl,
        replyToStoryType: replyToStoryType,
        replyToStoryId: replyToStoryId,
        localPath: localPath, // ✅ أضف هذا السطر
      );

      // ✅ تخزين محليًا في Hive
      final chatBox = await openChatBox(_chatKey(senderId, receiverId));
      await chatBox.put(message.id, message);

      // ✅ إرسال إلى Firestore (الطرفين)
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .add(message.toMap());

      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId)
          .collection('messages')
          .add(message.toMap());

      // ✅ تحديث بيانات المحادثة الأخيرة
      final receiverChatRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId);

      final lastMessagePreview = switch (contentType) {
        'image' => 'Image 🖼️',
        'video' => 'Video 🎥',
        'audio' => 'Audio 🎵',
        _ => content,
      };

      await _firestore.runTransaction((transaction) async {
        final receiverChatSnapshot = await transaction.get(receiverChatRef);
        int currentUnreadMessages = receiverChatSnapshot.exists
            ? receiverChatSnapshot.get('unreadMessages') ?? 0
            : 0;

        transaction.set(receiverChatRef, {
          'lastMessage': lastMessagePreview,
          'timestamp': Timestamp.fromDate(timestamp),
          'receiverName': senderName,
          'receiverUsername': senderUsername,
          'receiverImage': senderImage,
          'unreadMessages': currentUnreadMessages + 1,
        }, SetOptions(merge: true));
      });

      final senderChatRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId);

      await senderChatRef.set({
        'lastMessage': lastMessagePreview,
        'timestamp': Timestamp.fromDate(timestamp),
        'receiverName': receiverName,
        'receiverUsername': receiverUsername,
        'receiverImage': receiverImage,
        'unreadMessages': 0,
      }, SetOptions(merge: true));

      // ✅ إرسال إشعار
      final receiverDoc =
      await _firestore.collection('users').doc(receiverId).get();
      final receiverFcmToken = receiverDoc.data()?['fcmToken'];

      if (receiverFcmToken != null && receiverFcmToken.isNotEmpty) {
        await NotificationController.sendPushNotification(
          token: receiverFcmToken,
          title: senderName,
          body: lastMessagePreview,
        );
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }


  Future<void> deleteMessageLocally(String messageId) async {
    messages.removeWhere((msg) => msg.id == messageId);
  }

  Future<void> deleteMessageForAll(String messageId) async {
    try {
      String senderId = box.read('user_id');
      String receiverId = box.read('chat_with');

      var paths = [
        _firestore
            .collection('users')
            .doc(senderId)
            .collection('chats')
            .doc(receiverId)
            .collection('messages'),
        _firestore
            .collection('users')
            .doc(receiverId)
            .collection('chats')
            .doc(senderId)
            .collection('messages'),
      ];

      for (var path in paths) {
        final snapshot = await path.where('id', isEqualTo: messageId).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      messages.removeWhere((msg) => msg.id == messageId);
    } catch (e) {
      print("Error deleting message for all: $e");
    }
  }

  Future<void> forwardMessage(MessageModel message) async {
    // Open your contact picker screen or implement logic as needed
    print("Forward message: ${message.content}");
    // You would typically navigate to a screen and call sendMessage from there
  }

  Future<void> editMessage(MessageModel message) async {
    // You can open a bottom sheet or dialog to edit the message
    print("Edit message: ${message.content}");
    // After editing, update the message in both sender and receiver collections
  }

  Future<void> replyToMessage(MessageModel message) async {
    // You can set this message as the message being replied to
    print("Reply to message: ${message.content}");
    // Then handle UI display and storage in sendMessage accordingly
  }

  Future<void> pickMedia(
      String senderId, String receiverId, ImageSource source, bool isVideo) async {
    try {
      bool permissionGranted = false;

      if (source == ImageSource.gallery) {
        final status = await Permission.photos.status;
        if (status.isGranted) {
          permissionGranted = true;
        } else {
          final result = await Permission.photos.request();
          permissionGranted = result.isGranted;
        }
      } else if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isGranted) {
          permissionGranted = true;
        } else {
          final result = await Permission.camera.request();
          permissionGranted = result.isGranted;
        }
      }

      if (!permissionGranted) {
        Get.snackbar("رفض الإذن", "يرجى منح صلاحية الوصول للمتابعة.");
        return;
      }

      final XFile? mediaFile = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source);

      if (mediaFile == null) {
        Get.snackbar("إلغاء", "لم يتم اختيار أي ملف.");
        return;
      }

      File originalFile = File(mediaFile.path);

      if (!await originalFile.exists()) {
        Get.snackbar("خطأ", "الملف غير موجود أو غير صالح.");
        return;
      }

      // ✂️ لو كانت صورة، افتح ImageCropper
      if (!isVideo) {
        final CroppedFile? cropped = await ImageCropper().cropImage(
          sourcePath: originalFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          // cropStyle: CropStyle.rectangle,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'تعديل الصورة',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              // initAspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
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
      }

      print("📸 تم اختيار الملف: ${originalFile.path}");

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String fileType = isVideo ? "video" : "image";

      final Directory tempDir = await getTemporaryDirectory();
      final String safePath = '${tempDir.path}/$fileName';
      final File safeFile = await originalFile.copy(safePath);

      print("📁 نسخة آمنة محفوظة في: $safePath");

      File fileToUpload = safeFile;

      if (!isVideo) {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          safeFile.absolute.path,
          quality: 70,
          format: CompressFormat.jpeg,
        );

        if (compressedBytes != null) {
          final compressedFile = File('${tempDir.path}/compressed_$fileName.jpg');
          await compressedFile.writeAsBytes(compressedBytes);
          fileToUpload = compressedFile;
          print("📦 الحجم بعد الضغط: ${await compressedFile.length()} bytes");
        } else {
          print("⚠️ فشل الضغط، سيتم استخدام الملف الأصلي.");
        }
      }

      String safeSenderId = Uri.encodeComponent(senderId);
      String safeReceiverId = Uri.encodeComponent(receiverId);

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("chats/$safeSenderId/$safeReceiverId/$fileName");

      print("🚀 بدء الرفع إلى: chats/$safeSenderId/$safeReceiverId/$fileName");

      UploadTask uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: isVideo ? 'video/mp4' : 'image/jpeg',
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String fileUrl = await snapshot.ref.getDownloadURL();

      print("✅ تم الرفع بنجاح. رابط التحميل: $fileUrl");

      await sendMessage(
        senderId,
        receiverId,
        fileUrl,
        fileType,
        replyToStoryUrl: null,
        replyToStoryType: null,
        replyToStoryId: null,
        localPath: safeFile.path,
      );

      Get.snackbar("تم الإرسال", "تم إرسال الملف بنجاح.");
    } catch (e) {
      print("❌ Error picking media: $e");
      Get.snackbar("خطأ", "فشل إرسال الملف: $e");
    }
  }


  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      var messagesRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId)
          .collection('messages');

      var snapshot = await messagesRef.where('isRead', isEqualTo: false).get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId)
          .update({
        'unreadMessages': 0,
      });
    } catch (e) {
      print("Error marking messages as read: \$e");
    }
  }

  // Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
  //   return _firestore
  //       .collection('users')
  //       .doc(senderId)
  //       .collection('chats')
  //       .doc(receiverId)
  //       .collection('messages')
  //       .orderBy('timestamp')
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs
  //       .map((doc) => MessageModel.fromMap(doc.data()))
  //       .toList());
  // }

  Map<String, String?> videoThumbnails = {};

  Future<void> prepareVideoThumbnails(List<MessageModel> messages) async {
    for (final msg in messages) {
      if (msg.contentType == "video" && !videoThumbnails.containsKey(msg.content)) {
        final thumb = await VideoThumbnailCache().getThumbnail(msg.content);
        videoThumbnails[msg.content] = thumb;
      }
    }
  }

  Future<void> generateAndCacheThumbnail(String videoUrl) async {
    if (videoThumbnails.containsKey(videoUrl)) return;

    final safeFileName = md5.convert(utf8.encode(videoUrl)).toString();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/thumb_$safeFileName.jpg';

    final file = File(filePath);
    if (await file.exists()) {
      videoThumbnails[videoUrl] = filePath;
    } else {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: filePath,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      if (thumbnail != null) {
        videoThumbnails[videoUrl] = thumbnail;
      }
    }
  }


  Stream<List<MessageModel>> getMediaMessages(String senderId, String receiverId) {
    return _firestore
        .collection('users')
        .doc(senderId)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .where('contentType', whereIn: ['image', 'video', 'audio']) // فلترة حسب نوع المحتوى
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()))
        .toList());
  }

}
