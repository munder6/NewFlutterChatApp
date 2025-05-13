import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/new_chat_controller.dart';
import '../screens/chat_screen.dart';
import '../app_theme.dart';

class UserList extends StatelessWidget {
  final NewChatController newChatController;

  UserList({required this.newChatController});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      // ✅ عرض مؤشر تحميل عند البداية
      if (newChatController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      // ✅ في حال ما كتب شي، ما نعرض شيء إطلاقًا
      if (newChatController.searchQuery.value.trim().isEmpty) {
        return Center(
          child: Text(
            "Start typing to search users...",
            style: TextStyle(
              color: AppTheme.getTextColor(isDarkMode),
              fontSize: 14,
            ),
          ),
        );
      }

      // ✅ لا يوجد نتائج مطابقة
      if (newChatController.usersList.isEmpty) {
        return Center(
          child: Text(
            "No users found",
            style: TextStyle(
              color: AppTheme.getTextColor(isDarkMode),
              fontSize: 14,
            ),
          ),
        );
      }

      // ✅ عرض النتائج الفعلية
      return ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.zero,
        itemCount: newChatController.usersList.length,
        itemBuilder: (context, index) {
          var user = newChatController.usersList[index];

          String profileImageUrl = user.profileImage.isNotEmpty
              ? user.profileImage
              : 'https://i.pravatar.cc/150?u=${user.id}';

          return ListTile(
            dense: true,
            visualDensity: VisualDensity(vertical: -1),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            tileColor: Colors.transparent,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.getTextColor(isDarkMode),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              "@${user.username}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: CachedNetworkImageProvider(profileImageUrl),
              backgroundColor: Colors.transparent,
            ),
            trailing: Icon(
              EvaIcons.messageCircleOutline,
              color: isDarkMode ? Colors.white : Colors.blue[700],
            ),
            onTap: () {
              Get.to(() =>
                  ChatScreen(
                    receiverId: user.id,
                    receiverName: user.fullName,
                    receiverUsername: user.username,
                    receiverImage: profileImageUrl,
                    bio: user.bio,
                    birthdate: user.birthDate ?? "Not Set",
                  ));
            }
          );
        },
      );
    });
  }
}
