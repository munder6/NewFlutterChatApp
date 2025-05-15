import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat; // فقط لجلب DateFormat
import '../controller/homescreeen_controller.dart';
import '../models/conversation_model.dart';
import '../screens/chat_screen.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../widgets/users_stories_list.dart';
import '../widgets/search_box.dart';
import '../focused_menu.dart';
import '../modals.dart';

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
      if (mounted) {
        setState(() {
          allConversations = data;
          isLoading = false;
        });
      }
    });
  }

  TextDirection getTextDirection(String text) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color menuBg = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200;

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
      padding: EdgeInsets.only(top: 110, bottom: 110),
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
              onSubmitted: (value) {
                setState(() {
                  searchQuery = value;
                });
                FocusScope.of(context).unfocus();
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

            return FocusedMenuHolder(
              onPressed: () {},
              menuWidth: MediaQuery.of(context).size.width * 0.5,
              blurSize: 5,
              leftSide: MediaQuery.of(context).size.width / 2.1,
              rightSide: 8,
              menuBoxDecoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              animateMenuItems: true,
              duration: Duration(milliseconds: 200),
              menuItems: [
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Delete", style: TextStyle(color: textColor)),
                  trailingIcon: Icon(EvaIcons.trashOutline, color: iconColor),
                  onPressed: () {},
                ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Delete for everyone", style: TextStyle(color: Colors.red)),
                  trailingIcon: Icon(EvaIcons.trash2Outline, color: Colors.red),
                  onPressed: () {},
                ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Archive", style: TextStyle(color: textColor)),
                  trailingIcon: Icon(EvaIcons.archiveOutline, color: iconColor),
                  onPressed: () {},
                ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Block", style: TextStyle(color: textColor)),
                  trailingIcon: Icon(Icons.block, color: iconColor),
                  onPressed: () {},
                ),
              ],
              child: StreamBuilder<bool>(
                stream: widget.homeController.getUserTypingStatus(conversation.id),
                builder: (context, typingSnapshot) {
                  return StreamBuilder<bool>(
                    stream: widget.homeController.getUserOnlineStatus(conversation.id),
                    builder: (context, onlineSnapshot) {
                      bool isOnline = onlineSnapshot.data ?? false;
                      return Stack(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade200,
                              radius: 27,
                              backgroundImage: CachedNetworkImageProvider(profileImageUrl),
                            ),
                            title: Directionality(
                              textDirection: getTextDirection(conversation.receiverName),
                              child: Text(
                                textAlign:  TextAlign.left,

                                conversation.receiverName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.getTextColor(isDarkMode),
                                ),
                              ),
                            ),
                            subtitle: Directionality(
                              textDirection: getTextDirection(conversation.lastMessage),
                              child: Text(
                                textAlign:  TextAlign.left,
                                typingSnapshot.data == true
                                    ? "Typing..."
                                    : conversation.lastMessage,
                                style: TextStyle(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTimestamp(conversation.timestamp, conversation.unreadMessages),
                                  style: TextStyle(
                                    color: conversation.unreadMessages > 0 ? Colors.red : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: conversation.unreadMessages > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
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
                                bio: user.bio,
                                birthdate: user.birthDate.toString(),
                              ));
                            },
                          ),
                          if (isOnline)
                            Positioned(
                              top: 46,
                              left: 55,
                              child: Container(
                                width: 15,
                                height: 15,
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
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp, int unreadMessages) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    String formattedTime = '';
    if (difference.inMinutes < 1) {
      formattedTime = "Now";
    } else if (difference.inHours < 1) {
      formattedTime = "${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      formattedTime = "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      formattedTime = "${difference.inDays}d ago";
    } else {
      formattedTime = DateFormat('dd/MM/yyyy').format(timestamp);
    }

    return formattedTime;
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
