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

  // final Map<String, String> senderImageCache = {};

  Future<String> getSenderImage(String senderId) async {
    if (senderImageCache.containsKey(senderId)) {
      return senderImageCache[senderId]!;
    }

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    final imageUrl = snapshot.data()?['profileImageUrl'] ?? 'https://i.pravatar.cc/150?u=$senderId';
    senderImageCache[senderId] = imageUrl;
    return imageUrl;
  }

  final Map<String, String> senderImageCache = {};

  Future<void> preloadSenderImages(List<MessageModel> messages) async {
    for (final msg in messages) {
      if (!senderImageCache.containsKey(msg.senderId)) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(msg.senderId)
              .get();

          final imageUrl = snapshot.data()?['profileImageUrl'] ??
              'https://i.pravatar.cc/150?u=${msg.senderId}';

          senderImageCache[msg.senderId] = imageUrl;
        } catch (e) {
          print("⚠️ Error loading image for ${msg.senderId}: $e");
        }
      }
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
        .map((snapshot) {
      final newMessages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      messages.assignAll(newMessages);
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
        String? localPath,
      }) async {
    try {
      String senderName = box.read('fullName') ?? 'Unknown Sender';
      String senderUsername = box.read('username') ?? 'UnknownUsername';
      String senderImage = box.read('profileImageUrl') ?? '';

      String? receiverName = box.read('receiverName_$receiverId');
      String? receiverUsername = box.read('receiverUsername_$receiverId');
      String? receiverImage = box.read('receiverImage_$receiverId');

      if (receiverName == null || receiverUsername == null || receiverImage == null) {
        DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
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
      final provisionalTimestamp = DateTime.now();

      MessageModel message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        contentType: contentType,
        isRead: false,
        timestamp: provisionalTimestamp,
        receiverName: receiverName ?? 'Unknown Receiver',
        receiverUsername: receiverUsername ?? 'UnknownUsername',
        replyToStoryUrl: replyToStoryUrl,
        replyToStoryType: replyToStoryType,
        replyToStoryId: replyToStoryId,
        localPath: localPath,
      );

      final messageData = message.toMap(useServerTimestamp: true);

      // Add to sender's Firestore
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .add(messageData);

      // Add to receiver's Firestore
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId)
          .collection('messages')
          .add(messageData);

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
          'timestamp': FieldValue.serverTimestamp(),
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
        'timestamp': FieldValue.serverTimestamp(),
        'receiverName': receiverName,
        'receiverUsername': receiverUsername,
        'receiverImage': receiverImage,
        'unreadMessages': 0,
      }, SetOptions(merge: true));

      // Send push notification (v1)
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final receiverFcmToken = receiverDoc.data()?['fcmToken'];

      if (receiverFcmToken != null && receiverFcmToken.isNotEmpty) {
        await NotificationController.sendPushNotificationV1(
          token: receiverFcmToken,
          title: senderName,
          body: lastMessagePreview,
        );
        print('✅ Notification sent successfully to $receiverUsername');
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }



  void listenToMessages(String senderId, String receiverId) {
    getMessages(senderId, receiverId).listen((msgList) {
      messages.assignAll(msgList);
    });
  }


  Future<void> deleteMessageLocally(String messageId, String receiverId) async {
    try {
      final String senderId = box.read('user_id');

      // حذف من Firestore (فقط من مسار المستخدم الحالي)
      final userMessagesRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId)
          .collection('messages');

      // جلب الرسالة قبل الحذف
      final snapshot = await userMessagesRef.where('id', isEqualTo: messageId).get();
      if (snapshot.docs.isEmpty) {
        print("❌ Message not found in Firestore.");
        return;
      }

      final docToDelete = snapshot.docs.first;
      final message = MessageModel.fromMap(docToDelete.data());
      await docToDelete.reference.delete();

      // حذف من القائمة في الذاكرة
      messages.removeWhere((msg) => msg.id == messageId);

      // فحص ما إذا كانت الرسالة هي الأخيرة
      final latestSnapshot = await userMessagesRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final lastMsg = latestSnapshot.docs.isNotEmpty
          ? MessageModel.fromMap(latestSnapshot.docs.first.data())
          : null;

      final wasDeletedLatest = lastMsg == null ||
          message.timestamp.isAtSameMomentAs(lastMsg.timestamp) ||
          message.timestamp.isAfter(lastMsg.timestamp);

      if (wasDeletedLatest) {
        // تحديث المحادثة الأخيرة للمستخدم الحالي فقط
        final newLastSnapshot = await userMessagesRef
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        final newLast = newLastSnapshot.docs.isNotEmpty
            ? MessageModel.fromMap(newLastSnapshot.docs.first.data())
            : null;

        final preview = switch (newLast?.contentType) {
          'image' => 'Image 🖼️',
          'video' => 'Video 🎥',
          'audio' => 'Audio 🎵',
          _ => newLast?.content ?? '',
        };

        final userChatRef = _firestore
            .collection('users')
            .doc(senderId)
            .collection('chats')
            .doc(receiverId);

        await userChatRef.set({
          'lastMessage': preview,
          'timestamp': newLast != null
              ? Timestamp.fromDate(newLast.timestamp)
              : FieldValue.delete(),
        }, SetOptions(merge: true));

        print("✅ lastMessage updated for current user only to: $preview");
      } else {
        print("✅ Message deleted without updating lastMessage.");
      }
    } catch (e) {
      print("❌ Error deleting message locally: $e");
    }
  }





  Future<void> deleteMessageForAll(String messageId, String receiverId) async {
    try {
      final String senderId = box.read('user_id');

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

      // تحديث قائمة الرسائل في الذاكرة فقط
      messages.removeWhere((msg) => msg.id == messageId);

      // تحديث lastMessage في الطرفين
      await _updateLastMessageAfterDelete(senderId, receiverId);

    } catch (e) {
      print("❌ Error deleting message for all: $e");
    }
  }

  Future<void> _updateLastMessageAfterDelete(String senderId, String receiverId) async {
    try {
      // المسار إلى رسائل المحادثة (من Firestore)
      final messagesRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId)
          .collection('messages');

      // جلب الرسائل مرتبة تنازلياً حسب الوقت
      final snapshot = await messagesRef.orderBy('timestamp', descending: true).limit(1).get();

      final lastMsg = snapshot.docs.isNotEmpty
          ? MessageModel.fromMap(snapshot.docs.first.data())
          : null;

      final lastPreview = switch (lastMsg?.contentType) {
        'image' => 'Image 🖼️',
        'video' => 'Video 🎥',
        'audio' => 'Audio 🎵',
        _ => lastMsg?.content ?? '',
      };

      final senderChatRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId);

      final receiverChatRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId);

      final data = {
        'lastMessage': lastPreview,
        'timestamp': lastMsg != null ? Timestamp.fromDate(lastMsg.timestamp) : FieldValue.delete(),
      };

      await senderChatRef.set(data, SetOptions(merge: true));
      await receiverChatRef.set(data, SetOptions(merge: true));

      print("✅ lastMessage updated to: $lastPreview");
    } catch (e) {
      print("❌ Error updating lastMessage: $e");
    }
  }


  Future<void> forwardMessage(MessageModel message) async {
    // Open your contact picker screen or implement logic as needed
    print("Forward message: ${message.content}");
    // You would typically navigate to a screen and call sendMessage from there
  }

// ✅ Step 1: تعديل دالة editMessage داخل ChatController
  Future<void> editMessage(MessageModel message, String newContent) async {
    try {
      final senderId = box.read('user_id');
      final receiverId = message.receiverId;

      // تحديث المحتوى مؤقتًا في الذاكرة
      message.content = newContent;

      // ✅ تعديل الرسالة لدى الطرفين في Firestore
      for (final path in [
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
      ]) {
        final snapshot = await path.where('id', isEqualTo: message.id).get();
        for (var doc in snapshot.docs) {
          await doc.reference.update({
            'content': newContent,
          });
        }
      }

      // ✅ تحديث الرسالة داخل القائمة في الذاكرة
      int index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index].content = newContent;
        messages.refresh();
      }

      // ✅ تحديث lastMessage إذا كانت هذه هي آخر رسالة
      final lastMessage = messages.isNotEmpty ? messages.last : null;

      if (lastMessage != null && lastMessage.id == message.id) {
        final preview = switch (message.contentType) {
          'image' => 'Image 🖼️',
          'video' => 'Video 🎥',
          'audio' => 'Audio 🎵',
          _ => newContent,
        };

        final update = {
          'lastMessage': preview,
          'timestamp': Timestamp.fromDate(message.timestamp),
        };

        final senderChatRef = _firestore
            .collection('users')
            .doc(senderId)
            .collection('chats')
            .doc(receiverId);

        final receiverChatRef = _firestore
            .collection('users')
            .doc(receiverId)
            .collection('chats')
            .doc(senderId);

        await senderChatRef.set(update, SetOptions(merge: true));
        await receiverChatRef.set(update, SetOptions(merge: true));
      }

    } catch (e) {
      print("❌ Error editing message: $e");
    }
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
        .where('contentType', whereIn: ['image', 'video', 'audio'])
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

}
