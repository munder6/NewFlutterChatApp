import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controller/homescreeen_controller.dart';
import '../controller/story_controller.dart';
import '../screens/chat_screen.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../models/conversation_model.dart';
import '../models/story_model.dart';
import '../screens/story_camera_screen.dart';
import '../screens/view_story_screen.dart';
import '../widgets/dashed_circle_avatar.dart';

class HorizontalUserStoryList extends StatelessWidget {
  final HomeController homeController;
  final StoryController storyController = Get.put(StoryController());
  final String userId;

  HorizontalUserStoryList({required this.homeController, required this.userId});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = GetStorage().read('user_data') ?? {};


    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: StreamBuilder<List<ConversationModel>>(
        stream: homeController.getConversations(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox();

          final conversations = snapshot.data!;
          final allUsers = [...{userId, ...conversations.map((e) => e.id)}];

          return ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: allUsers.length,
            itemBuilder: (context, index) {
              final currentUserId = allUsers.elementAt(index);
              final isCurrentUser = currentUserId == userId;

              return FutureBuilder<UserModel>(
                future: homeController.getUserById(currentUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return SizedBox();

                  final user = userSnapshot.data!;
                  final profileImageUrl = user.profileImage.isNotEmpty
                      ? user.profileImage
                      : 'https://i.pravatar.cc/150?u=${user.id}';

                  return StreamBuilder<List<StoryModel>>(
                    stream: storyController.getUserStories(currentUserId),
                    builder: (context, storySnapshot) {
                      final hasStory = storySnapshot.hasData && storySnapshot.data!.isNotEmpty;
                      final storyCount = storySnapshot.data?.length ?? 0;

                      return StreamBuilder<bool>(
                        stream: homeController.getUserOnlineStatus(currentUserId),
                        builder: (context, onlineSnapshot) {
                          final isOnline = onlineSnapshot.data ?? false;

                          return GestureDetector(
                            onTap: () async {
                              if (isCurrentUser) {
                                final userStories = await storyController.getUserStories(userId).first;
                                if (userStories.isNotEmpty) {
                                  Get.to(() => StoryViewScreen(
                                    ownerId: currentUserId,
                                    stories: userStories,
                                    isOwner: true,
                                  ));
                                } else {
                                  Get.to(() => StoryCameraScreen());
                                }
                              } else {
                                if (hasStory) {
                                  Get.to(() => StoryViewScreen(
                                    ownerId: currentUserId,
                                    stories: storySnapshot.data!,
                                    isOwner: false,
                                  ));
                                } else {
                                  Get.to(() =>  ChatScreen(
                                    receiverId: user.id,
                                    receiverName: user.fullName,
                                    receiverUsername: user.username,
                                    receiverImage: profileImageUrl,
                                    bio: user.bio,
                                    birthdate: user.birthDate.toString(),
                                  ));
                                }
                              }
                            },
                            child: Container(
                              width: 75,
                              margin: EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      DashedCircleAvatar(
                                        imageUrl: profileImageUrl,
                                        segments: storyCount,
                                        radius: 48,
                                        hasStory: hasStory,
                                      ),
                                      if (isCurrentUser)
                                        Positioned(
                                          bottom: 18,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              Get.to(() => StoryCameraScreen());
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isDarkMode ? Colors.black : Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDarkMode ? Colors.black : Colors.white,
                                                ),
                                              ),
                                              width: 26,
                                              height: 26,
                                              child: Icon(EvaIcons.plusCircle, color: Colors.blue[700]),
                                            ),
                                          ),
                                        ),
                                      if (!isCurrentUser && isOnline)
                                        Positioned(
                                          bottom: 23,
                                          right: 8,
                                          child: Container(
                                            width: 17,
                                            height: 17,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDarkMode ? Colors.black : Colors.white,
                                                width: 2.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 2,
                                        left: 0,
                                        right: 0,
                                        child: Text(
                                          isCurrentUser ? 'Your Story' : user.fullName.split(' ').first,
                                          textAlign: TextAlign.center, // ضروري عشان يتوسّط
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.getTextColor(isDarkMode),
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
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
      ),
    );
  }
}
