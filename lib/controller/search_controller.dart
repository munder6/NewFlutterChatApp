import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/conversation_model.dart';

class SearchConversationsController extends GetxController {
  var searchResults = <ConversationModel>[].obs;
  var isLoading = false.obs;

  // دالة البحث عن المحادثات
  void searchConversations(String query, String userId) async {
    if (query.isEmpty) {
      searchResults.clear(); // إذا كان الاستعلام فارغًا، يتم مسح النتائج
      return;
    }

    isLoading.value = true; // تعيين حالة التحميل إلى true عند بدء البحث

    try {
      // تحويل النص المدخل إلى أحرف صغيرة
      String queryLowerCase = query.toLowerCase();

      // البحث عن المحادثات في Firestore باستخدام where
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chats')
          .where('receiverName', isGreaterThanOrEqualTo: queryLowerCase)
          .where('receiverName', isLessThanOrEqualTo: queryLowerCase + '\uf8ff')
          .get();

      // فلترة النتائج بناءً على الاستعلام (بدون التفرقة بين الأحرف الكبيرة والصغيرة)
      List<ConversationModel> conversations = querySnapshot.docs.map((doc) {
        return ConversationModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      searchResults.value = conversations; // تعيين نتائج البحث
    } catch (e) {
      print("Error searching conversations: $e");
    } finally {
      isLoading.value = false; // تعيين حالة التحميل إلى false بعد انتهاء البحث
    }
  }
}
