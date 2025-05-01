import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/new_chat_controller.dart';
import '../widgets/search_box.dart';
import '../widgets/user_list.dart';
import '../app_theme.dart';

class NewChatScreen extends StatefulWidget {
  @override
  _NewChatScreenState createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final NewChatController newChatController = Get.put(NewChatController());
  final TextEditingController searchControllerText = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // 🔹 عنوان الصفحة فقط بدون AppBar
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              "Start New Chat",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: AppTheme.getTextColor(isDarkMode),
              ),
            ),
          ),

          // 🔹 Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
            child: SearchBox(
              searchControllerText: searchControllerText,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
                newChatController.searchUsers(searchQuery);
              },
            ),
          ),

          // 🔹 قائمة المستخدمين بعد البحث فقط
          Expanded(
            child: searchQuery.isEmpty
                ? Center(
              child: Text(
                "Start typing to search users...",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : UserList(newChatController: newChatController),
          ),
        ],
      ),
    );
  }
}
