import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../app_theme.dart';
import '../controller/story_controller.dart';
import '../controller/homescreeen_controller.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../screens/story_camera_screen.dart';
import '../screens/view_story_screen.dart';

class StoriesGridScreen extends StatefulWidget {
  @override
  State<StoriesGridScreen> createState() => _StoriesGridScreenState();
}

class _StoriesGridScreenState extends State<StoriesGridScreen> {
  final StoryController storyController = Get.put(StoryController());
  final HomeController homeController = Get.put(HomeController());

  late Future<Map<String, List<StoryModel>>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = storyController.getFirstStoriesWithAllData();
  }

  Future<void> _refreshStories() async {
    setState(() {
      _storiesFuture = storyController.getFirstStoriesWithAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = GetStorage().read('user_id');
    final String profileImageUrl =
        GetStorage().read('profileImageUrl') ?? 'https://i.pravatar.cc/150';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle =
    isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(55),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
              child: Container(
                height: 110,
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                alignment: Alignment.centerLeft,
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.5),
                child: Text(
                  "Stories",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(isDarkMode),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshStories,
          color: Colors.blueAccent,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          displacement: 60,
          strokeWidth: 2.5,
          triggerMode: RefreshIndicatorTriggerMode.onEdge,
          notificationPredicate: (_) => true,
          child: FutureBuilder<Map<String, List<StoryModel>>>(
            future: _storiesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CupertinoActivityIndicator(radius: 15));
              }

              final storyData = snapshot.data!;
              final userIds =
              storyData.keys.where((id) => id != currentUserId).toList();

              return FutureBuilder<List<UserModel>>(
                future: Future.wait(
                    userIds.map((id) => homeController.getUserById(id))),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return Center(child: CupertinoActivityIndicator());
                  }

                  final users = userSnapshot.data!;
                  final widgets = <Widget>[];

                  final myStories = storyData[currentUserId];
                  final myFirstStory = myStories?.isNotEmpty == true
                      ? myStories!.first
                      : null;

                  widgets.add(
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (myStories != null &&
                                myStories.isNotEmpty) {
                              Get.to(() => StoryViewScreen(
                                ownerId: currentUserId,
                                stories: myStories,
                                isOwner: true,
                              ));
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl:
                              myFirstStory?.mediaUrl ?? profileImageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Center(child: CupertinoActivityIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                        ),
                        if (myFirstStory?.mediaType == 'video')
                          Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 50, color: Colors.white70),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => Get.to(() => StoryCameraScreen()),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child:
                              Icon(Icons.add, size: 22, color: Colors.blue),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Text(
                            "Add to Story",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(1, 1),
                                )
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );

                  widgets.addAll(List.generate(users.length, (index) {
                    final user = users[index];
                    final stories = storyData[user.id]!;
                    final firstStory = stories.first;

                    return GestureDetector(
                      onTap: () {
                        Get.to(() => StoryViewScreen(
                          ownerId: user.id,
                          stories: stories,
                          isOwner: false,
                        ));
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: firstStory.mediaUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Center(child: CupertinoActivityIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                          if (firstStory.mediaType == 'video')
                            Center(
                              child: Icon(Icons.play_circle_fill,
                                  size: 50, color: Colors.white70),
                            ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundImage: CachedNetworkImageProvider(
                                  user.profileImage.isNotEmpty
                                      ? user.profileImage
                                      : 'https://i.pravatar.cc/150?u=${user.id}',
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                stories.length.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Text(
                              user.fullName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  )
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }));

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 25, 12, 12),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.58,
                      children: widgets,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

