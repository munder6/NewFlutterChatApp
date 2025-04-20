import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/homescreeen_controller.dart';
import '../models/conversation_model.dart';
import '../screens/chat_screen.dart';
import '../app_theme.dart'; // استيراد ملف AppTheme
import '../models/user_model.dart'; // استيراد UserModel

class ConversationList extends StatelessWidget {
  final HomeController homeController;
  final String userId;
  final String searchQuery;

  ConversationList({required this.homeController, required this.userId, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<ConversationModel>>(
      stream: homeController.getConversations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No conversations"));
        }

        // تصفية المحادثات بناءً على البحث
        var conversations = snapshot.data!;
        if (searchQuery.isNotEmpty) {
          conversations = conversations
              .where((c) => c.receiverName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              c.receiverUsername.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
        }

        return ListView.builder(
          padding: EdgeInsets.zero, // 🔥 هذا اللي يشيل الفراغ اللي تحت السيرش بوكس

          itemCount: conversations.length,
          itemBuilder: (context, index) {
            var conversation = conversations[index];

            return FutureBuilder<UserModel>(
              future: homeController.getUserById(conversation.id), // جلب بيانات المستخدم (الصورة الحقيقية)
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!userSnapshot.hasData) {
                  return SizedBox();
                }

                var user = userSnapshot.data!;
                String profileImageUrl = user.profileImage.isNotEmpty ? user.profileImage : 'https://i.pravatar.cc/150';

                return StreamBuilder<bool>(
                  stream: homeController.getUserTypingStatus(conversation.id), // مراقبة حالة الكتابة
                  builder: (context, typingSnapshot) {

                    return StreamBuilder<bool>(
                      stream: homeController.getUserOnlineStatus(conversation.id), // مراقبة حالة الـ isOnline
                      builder: (context, onlineSnapshot) {
                        bool isOnline = onlineSnapshot.data ?? false; // حالة أونلاين للمستخدم
                        return Card(
                          color: isDarkMode ? Colors.black : Colors.white, // لون الكارد بناءً على الوضع
                          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: -4, horizontal: 15),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: CachedNetworkImageProvider(profileImageUrl), // عرض الصورة باستخدام CachedNetworkImage
                            ),
                            title: Row(
                              children: [
                                Text(
                                  conversation.receiverName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.getTextColor(isDarkMode), // النص بناءً على الوضع
                                  ),
                                ),
                                SizedBox(width: 5),
                                // عرض النقطة الخضراء إذا كان المستخدم أونلاين
                                if (isOnline)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: typingSnapshot.connectionState == ConnectionState.waiting
                                ? SizedBox()
                                : Text(
                              typingSnapshot.data == true ? "Typing..." : conversation.lastMessage,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTimestamp(conversation.timestamp), // تنسيق الوقت
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 5),
                                _buildUnreadMessagesIndicator(conversation.unreadMessages), // عدد الرسائل غير المقروءة
                              ],
                            ),
                            onTap: () {
                              Get.to(() => ChatScreen(
                                receiverId: conversation.id,
                                receiverName: conversation.receiverName,
                                receiverUsername: conversation.receiverUsername,
                              ));
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // 🔹 دالة تنسيق الوقت لعرضه بالشكل الصحيح
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return "Now";
    if (difference.inHours < 1) return "${difference.inMinutes}m ago";
    if (difference.inDays < 1) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";

    return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
  }

  // 🔹 دالة لإنشاء الدائرة الخاصة بعدد الرسائل غير المقروءة
  Widget _buildUnreadMessagesIndicator(int unreadMessages) {
    if (unreadMessages == 0) return SizedBox(); // إخفاء الدائرة إذا لم يكن هناك رسائل غير مقروءة

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.red, // لون مميز
        shape: BoxShape.circle,
      ),
      child: Text(
        unreadMessages.toString(),
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
