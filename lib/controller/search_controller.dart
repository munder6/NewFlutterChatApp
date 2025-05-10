import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';

class SearchConversationsController extends GetxController {
  var searchResults = <ConversationModel>[].obs;
  var isLoading = false.obs;

  // البحث في محادثات المستخدم الحالي حسب الاسم
  void searchConversations(String query, String userId) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isLoading.value = true;

    try {
      String queryLowerCase = query.toLowerCase();

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chats')
          .where('receiverName', isGreaterThanOrEqualTo: queryLowerCase)
          .where('receiverName', isLessThanOrEqualTo: queryLowerCase + '')
          .get();

      List<ConversationModel> conversations = querySnapshot.docs.map((doc) {
        return ConversationModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      searchResults.value = conversations;
    } catch (e) {
      print("Error searching conversations: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // جلب بيانات المستخدم الكامل باستخدام الـ ID
  Future<UserModel> getUserById(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    } else {
      throw Exception("User not found");
    }
  }
}
