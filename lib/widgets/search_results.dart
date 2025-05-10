import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/search_controller.dart';
import '../models/user_model.dart';
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
          return FutureBuilder<UserModel>(
            future: searchController.getUserById(conversation.id),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return SizedBox();

              var user = userSnapshot.data!;
              String profileImageUrl = user.profileImage.isNotEmpty
                  ? user.profileImage
                  : 'https://i.pravatar.cc/150';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(profileImageUrl),
                ),
                title: Text(user.fullName),
                subtitle: Text(user.username),
                onTap: () {
                  Get.to(() => ChatScreen(
                    receiverId: user.id,
                    receiverName: user.fullName,
                    receiverUsername: user.username,
                    receiverImage: profileImageUrl,
                    bio: user.bio,
                    birthdate: user.birthDate.toString(),
                  ));
                },
              );
            },
          );
        },
      )
          : Center(child: Text("No conversations found")); // عرض رسالة إذا لم توجد نتائج
    });
  }
}
