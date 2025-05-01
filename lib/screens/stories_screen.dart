// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// import '../app_theme.dart';
// import '../widgets/dashed_circle_avatar.dart';
// import '../controller/homescreeen_controller.dart';
// import '../controller/story_controller.dart';
// import '../screens/story_camera_screen.dart';
// import '../screens/view_story_screen.dart';
// import '../models/story_model.dart';
// import '../models/user_model.dart';
//
// class StatusScreen extends StatelessWidget {
//   final StoryController storyController = Get.put(StoryController());
//   final HomeController homeController = Get.put(HomeController());
//   final String userId;
//
//   StatusScreen({required this.userId});
//
//   @override
//   Widget build(BuildContext context) {
//     bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     final textColor = isDarkMode ? Colors.white : Colors.black;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Updates", style: TextStyle(color: textColor)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//       ),
//       body: ListView(
//         padding: EdgeInsets.symmetric(horizontal: 16),
//         children: [
//           FutureBuilder<UserModel>(
//             future: homeController.getUserById(userId),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) return SizedBox();
//               final user = snapshot.data!;
//               final profileUrl = user.profileImage.isNotEmpty
//                   ? user.profileImage
//                   : 'https://i.pravatar.cc/150?u=${user.id}';
//
//               return ListTile(
//                 contentPadding: EdgeInsets.zero,
//                 leading: Stack(
//                   alignment: Alignment.bottomRight,
//                   children: [
//                     CircleAvatar(
//                       radius: 28,
//                       backgroundImage: CachedNetworkImageProvider(profileUrl),
//                     ),
//                     Positioned(
//                       child: GestureDetector(
//                         onTap: () => Get.to(() => StoryCameraScreen()),
//                         child: CircleAvatar(
//                           backgroundColor: Colors.green,
//                           radius: 10,
//                           child: Icon(Icons.add, size: 16, color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 title: Text("My Status", style: TextStyle(color: textColor)),
//                 subtitle: Text("Add to my status"),
//               );
//             },
//           ),
//           SizedBox(height: 20),
//
//           // Section: Recent Updates
//           StreamBuilder<List<UserModel>>(
//             stream: storyController.getUsersWithRecentStories(userId),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Recent updates", style: TextStyle(color: textColor)),
//                   SizedBox(height: 10),
//                   ...snapshot.data!.map((user) => _buildStatusTile(context, user, isDarkMode, recent: true)),
//                 ],
//               );
//             },
//           ),
//
//           SizedBox(height: 20),
//
//           // Section: Viewed Updates
//           StreamBuilder<List<UserModel>>(
//             stream: storyController.getUsersWithViewedStories(userId),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Viewed updates", style: TextStyle(color: textColor)),
//                   SizedBox(height: 10),
//                   ...snapshot.data!.map((user) => _buildStatusTile(context, user, isDarkMode, recent: false)),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusTile(BuildContext context, UserModel user, bool isDarkMode, {required bool recent}) {
//     final profileUrl = user.profileImage.isNotEmpty
//         ? user.profileImage
//         : 'https://i.pravatar.cc/150?u=${user.id}';
//
//     return StreamBuilder<List<StoryModel>>(
//       stream: storyController.getUserStories(user.id),
//       builder: (context, snapshot) {
//         final stories = snapshot.data ?? [];
//         final hasStory = stories.isNotEmpty;
//
//         return ListTile(
//           contentPadding: EdgeInsets.zero,
//           leading: DashedCircleAvatar(
//             imageUrl: profileUrl,
//             segments: stories.length,
//             radius: 28,
//             hasStory: hasStory,
//           ),
//           title: Text(
//             user.fullName,
//             style: TextStyle(
//               color: AppTheme.getTextColor(isDarkMode),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           subtitle: Text(
//             "${stories.isNotEmpty ? _formatTimestamp(stories.first.createdAt) : ''}",
//             style: TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//           onTap: () {
//             if (hasStory) {
//               Get.to(() => StoryViewScreen(
//                 ownerId: user.id,
//                 stories: stories,
//                 isOwner: false,
//               ));
//             }
//           },
//         );
//       },
//     );
//   }
//
//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final diff = now.difference(timestamp);
//     if (diff.inMinutes < 1) return "Now";
//     if (diff.inHours < 1) return "${diff.inMinutes}m ago";
//     if (diff.inDays < 1) return "${diff.inHours}h ago";
//     if (diff.inDays < 7) return "${diff.inDays}d ago";
//     return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
//   }
// }
