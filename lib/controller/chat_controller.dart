import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/message_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();

  // قائمة الرسائل
  var messages = <MessageModel>[].obs;

  // ✅ إرسال رسالة نصية أو وسائط
  Future<void> sendMessage(
      String senderId,
      String receiverId,
      String content,
      String contentType, {
        String? replyToStoryUrl,
        String? replyToStoryType,
        String? replyToStoryId,
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
          Map<String, dynamic>? receiverData =
          receiverDoc.data() as Map<String, dynamic>?;

          receiverName = receiverData?['fullName'] ?? 'Unknown Receiver';
          receiverUsername = receiverData?['username'] ?? 'UnknownUsername';
          receiverImage = receiverData?['profileImageUrl'] ?? '';

          box.write('receiverName_$receiverId', receiverName);
          box.write('receiverUsername_$receiverId', receiverUsername);
          box.write('receiverImage_$receiverId', receiverImage);
        }
      }

      String messageId = _firestore.collection('messages').doc().id;
      MessageModel message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        contentType: contentType,
        isRead: false,
        timestamp: Timestamp.now(),
        receiverName: receiverName ?? 'Unknown Receiver',
        receiverUsername: receiverUsername ?? 'UnknownUsername',
        replyToStoryUrl: replyToStoryUrl,
        replyToStoryType: replyToStoryType,
        replyToStoryId: replyToStoryId,
      );

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

      DocumentReference receiverChatRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot receiverChatSnapshot =
        await transaction.get(receiverChatRef);
        int currentUnreadMessages = receiverChatSnapshot.exists
            ? receiverChatSnapshot.get('unreadMessages') ?? 0
            : 0;

        transaction.set(receiverChatRef, {
          'lastMessage': content,
          'timestamp': Timestamp.now(),
          'receiverName': senderName,
          'receiverUsername': senderUsername,
          'receiverImage': senderImage,
          'unreadMessages': currentUnreadMessages + 1,
        }, SetOptions(merge: true));
      });

      DocumentReference senderChatRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId);

      await senderChatRef.set({
        'lastMessage': content,
        'timestamp': Timestamp.now(),
        'receiverName': receiverName,
        'receiverUsername': receiverUsername,
        'receiverImage': receiverImage,
        'unreadMessages': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      print("❌ Error sending message: $e");
    }
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

      print("📸 تم اختيار الملف: ${mediaFile.path}");

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

      await sendMessage(senderId, receiverId, fileUrl, fileType);
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

  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
    return _firestore
        .collection('users')
        .doc(senderId)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()))
        .toList());
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
