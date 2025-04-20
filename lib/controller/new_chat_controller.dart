import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class NewChatController extends GetxController {
  var usersList = <UserModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // جلب المستخدمين عند تشغيل الصفحة
  }

  // 🔹 جلب جميع المستخدمين من Firestore
  void fetchUsers() async {
    isLoading.value = true;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      usersList.value = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 البحث عن المستخدمين بالاسم أو اسم المستخدم
  void searchUsers(String query) {
    if (query.isEmpty) {
      fetchUsers(); // في حالة البحث فارغ، نعيد كل المستخدمين
      return;
    }

    query = query.toLowerCase();
    usersList.value = usersList.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }
}
