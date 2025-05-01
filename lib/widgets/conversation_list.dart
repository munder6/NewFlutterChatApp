import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/homescreeen_controller.dart';
import '../models/conversation_model.dart';
import '../screens/chat_screen.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../widgets/users_stories_list.dart';
import '../widgets/search_box.dart';

class ConversationList extends StatefulWidget {
  final HomeController homeController;
  final String userId;

  const ConversationList({required this.homeController, required this.userId});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final TextEditingController searchControllerText = TextEditingController();
  String searchQuery = "";
  List<ConversationModel> allConversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.homeController.getConversations(widget.userId).listen((data) {
      setState(() {
        allConversations = data;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    List<ConversationModel> filteredConversations = searchQuery.isEmpty
        ? allConversations
        : allConversations.where((c) {
      final name = c.receiverName.toLowerCase();
      final username = c.receiverUsername.toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();

    return isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredConversations.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: SearchBox(
              searchControllerText: searchControllerText,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          );
        }

        if (index == 1) {
          return HorizontalUserStoryList(
            homeController: widget.homeController,
            userId: widget.userId,
          );
        }

        var conversation = filteredConversations[index - 2];

        return FutureBuilder<UserModel>(
          future: widget.homeController.getUserById(conversation.id),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return SizedBox();

            var user = userSnapshot.data!;
            String profileImageUrl = user.profileImage.isNotEmpty
                ? user.profileImage
                : 'https://i.pravatar.cc/150';

            return StreamBuilder<bool>(
              stream: widget.homeController.getUserTypingStatus(conversation.id),
              builder: (context, typingSnapshot) {
                return StreamBuilder<bool>(
                  stream: widget.homeController.getUserOnlineStatus(conversation.id),
                  builder: (context, onlineSnapshot) {
                    bool isOnline = onlineSnapshot.data ?? false;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: CachedNetworkImageProvider(profileImageUrl),
                      ),
                      title: Row(
                        children: [
                          Text(
                            conversation.receiverName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.getTextColor(isDarkMode),
                            ),
                          ),
                          SizedBox(width: 5),
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
                      subtitle: Text(
                        typingSnapshot.data == true
                            ? "Typing..."
                            : conversation.lastMessage,
                        style: TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTimestamp(conversation.timestamp),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          SizedBox(height: 5),
                          _buildUnreadMessagesIndicator(conversation.unreadMessages),
                        ],
                      ),
                      onTap: () {
                        Get.to(() => ChatScreen(
                          receiverId: user.id,
                          receiverName: user.fullName,
                          receiverUsername: user.username,
                          receiverImage: profileImageUrl,
                        ));
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return "Now";
    if (difference.inHours < 1) return "${difference.inMinutes}m ago";
    if (difference.inDays < 1) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
  }

  Widget _buildUnreadMessagesIndicator(int unreadMessages) {
    if (unreadMessages == 0) return SizedBox();
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text(
        unreadMessages.toString(),
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
