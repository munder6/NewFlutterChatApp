import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class NewChatController extends GetxController {
  var usersList = <UserModel>[].obs;
  var allUsers = <UserModel>[]; // قائمة المستخدمين الأصلية (لا يتم عرضها مباشرة)
  var isLoading = false.obs;
  var searchQuery = ''.obs; // ← تخزين النص الحالي في مربع البحث

  @override
  void onInit() {
    super.onInit();
    preloadAllUsers(); // تحميل المستخدمين مرة واحدة عند تشغيل الشاشة
  }

  // 🔹 تحميل جميع المستخدمين من Firestore (مرة واحدة فقط)
  void preloadAllUsers() async {
    isLoading.value = true;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

      allUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("❌ Error fetching users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 البحث عن المستخدمين حسب الاسم أو اسم المستخدم
  void searchUsers(String query) {
    searchQuery.value = query; // ← تحديث النص الحالي في السيرش

    if (query.trim().isEmpty) {
      usersList.clear(); // لا تعرض شيء إذا ما في نص
      return;
    }

    final lowerQuery = query.toLowerCase();

    final filtered = allUsers.where((user) {
      return user.fullName.toLowerCase().contains(lowerQuery) ||
          user.username.toLowerCase().contains(lowerQuery);
    }).toList();

    usersList.assignAll(filtered);
  }
}
