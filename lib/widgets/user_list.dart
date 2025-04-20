import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/new_chat_controller.dart';
import '../screens/chat_screen.dart';

class UserList extends StatelessWidget {
  final NewChatController newChatController;

  UserList({required this.newChatController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (newChatController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (newChatController.usersList.isEmpty) {
        return Center(child: Text("No users found"));
      }

      return ListView.builder(
        itemCount: newChatController.usersList.length,
        itemBuilder: (context, index) {
          var user = newChatController.usersList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              title: Text(
                user.fullName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.grey),
              ),
              trailing: Icon(Icons.message, color: Color(0xFF6200EE)),
              onTap: () {
                Get.to(() => ChatScreen(
                  receiverId: user.id,
                  receiverName: user.fullName,
                  receiverUsername: user.username,
                ));
              },
            ),
          );
        },
      );
    });
  }
}
