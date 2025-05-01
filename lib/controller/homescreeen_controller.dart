import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart'; // استيراد Firebase Realtime Database
import '../models/conversation_model.dart';
import '../models/user_model.dart'; // إضافة UserModel

class HomeController extends GetxController {

  // قائمة المحادثات
  var conversations = <ConversationModel>[].obs;

  // دالة جلب المحادثات باستخدام Stream
  Stream<List<ConversationModel>> getConversations(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id; // 👈 مهم: لإرسال ID المستخدم الآخر (receiverId)
      return ConversationModel.fromMap(data);
    }).toList());
  }

  // ✅ جلب جميع المستخدمين اللي عندهم محادثات مع المستخدم الحالي
  Stream<List<UserModel>> getUsersWithChats(String currentUserId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> users = [];

      for (var doc in snapshot.docs) {
        String otherUserId = doc.id;
        try {
          var user = await getUserById(otherUserId);
          users.add(user);
        } catch (_) {}
      }

      return users;
    });
  }


  // دالة جلب بيانات المستخدم (الصورة الشخصية) بناءً على ID المستخدم
  Future<UserModel> getUserById(String userId) async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } else {
      throw Exception('User not found');
    }
  }

  // دالة جلب حالة الكتابة "isTyping" للطرف الآخر
  Stream<bool> getUserTypingStatus(String userId) {
    return FirebaseFirestore.instance
        .collection('users') // الوصول إلى مجموعة المستخدمين
        .doc(userId) // الوصول إلى مستند المستخدم
        .snapshots() // الاستماع للتغييرات في مستند المستخدم
        .map((snapshot) {
      var isTyping = snapshot.data()?['isTyping'] ?? false; // جلب قيمة isTyping من المستند
      return isTyping; // إرجاع حالة الكتابة
    });
  }

  // دالة جلب حالة "isOnline" للطرف الآخر
  Stream<bool> getUserOnlineStatus(String userId) {
    return FirebaseDatabase.instance
        .ref('status/$userId/isOnline')
        .onValue
        .map((event) {
      var isOnline = event.snapshot.value as bool? ?? false;
      return isOnline;
    });
  }

  // دالة تحديث آخر رسالة في المحادثة إلى "Typing..." عندما يبدأ الكتابة

}
