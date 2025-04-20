import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/search_controller.dart';
import '../screens/chat_screen.dart';

class SearchResults extends StatelessWidget {
  final SearchConversationsController searchController;

  SearchResults({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return searchController.isLoading.value
          ? Center(child: CircularProgressIndicator()) // عرض مؤشر التحميل أثناء البحث
          : searchController.searchResults.isNotEmpty
          ? ListView.builder(
        shrinkWrap: true,
        itemCount: searchController.searchResults.length,
        itemBuilder: (context, index) {
          var conversation = searchController.searchResults[index];
          return ListTile(
            title: Text(conversation.receiverName),
            subtitle: Text(conversation.receiverUsername),
            onTap: () {
              // عند الضغط على اسم المحادثة، ننتقل إلى شاشة المحادثة الخاصة به
              Get.to(() => ChatScreen(
                receiverId: conversation.id,
                receiverName: conversation.receiverName,
                receiverUsername: conversation.receiverUsername,
              ));
            },
          );
        },
      )
          : Center(child: Text("No conversations found")); // عرض رسالة إذا لم توجد نتائج
    });
  }
}
