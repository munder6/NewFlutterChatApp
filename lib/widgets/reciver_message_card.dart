import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:meassagesapp/widgets/reply_to_story_bubble.dart';
import 'package:meassagesapp/widgets/text_message_bubble.dart';
import 'package:meassagesapp/widgets/video_message_bubble.dart';
import '../controller/chat_controller.dart';
import '../focused_menu.dart';
import '../modals.dart';
import '../models/message_model.dart';
import 'audio_message_bubble.dart';
import 'image_message_bubble.dart';

class ReceiverMessageCard extends StatefulWidget {
  final MessageModel message;
  final MessageModel? previousMessage;
  final MessageModel? nextMessage;
  final bool isLastInConversation;

  const ReceiverMessageCard({
    super.key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
    required this.isLastInConversation,
  });

  @override
  State<ReceiverMessageCard> createState() => _ReceiverMessageCardState();
}

class _ReceiverMessageCardState extends State<ReceiverMessageCard> {
  String? senderImageUrl;

  @override
  void initState() {
    super.initState();
    _loadSenderImage();
  }

  Future<void> _loadSenderImage() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.message.senderId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          senderImageUrl = data['profileImageUrl'] ??
              'https://i.pravatar.cc/150?u=${widget.message.senderId}';
        });
      }
    } catch (e) {
      print("❌ Failed to load sender image: $e");
    }
  }

  bool _hasTimeGap(DateTime prev, DateTime current) {
    return current.difference(prev).inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color iconColor = isDark ? Colors.white70 : Colors.black87;
    final Color menuBg = isDark ? Colors.grey.shade900 : Colors.grey.shade200;

    bool isFirstInGroup = widget.previousMessage == null ||
        widget.previousMessage!.senderId != widget.message.senderId ||
        _hasTimeGap(widget.previousMessage!.timestamp, widget.message.timestamp);

    bool isLastInGroup = widget.nextMessage == null ||
        widget.nextMessage!.senderId != widget.message.senderId ||
        _hasTimeGap(widget.message.timestamp, widget.nextMessage!.timestamp);

    BorderRadiusGeometry borderRadius;
    if (isFirstInGroup && isLastInGroup) {
      borderRadius = BorderRadius.circular(50);
    } else if (isFirstInGroup) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(20),
      );
    } else if (isLastInGroup) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    } else {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(20),
      );
    }

    final ChatController chatController = Get.find<ChatController>();

    final Widget bubbleWidget = Builder(
      builder: (_) {
        switch (widget.message.contentType) {
          case "text":
            return TextMessageBubble(message: widget.message, borderRadius: borderRadius, isSender: false);
          case "image":
            return ImageMessageBubble(message: widget.message, borderRadius: borderRadius, isSender: false);
          case "audio":
            return AudioMessageBubble(message: widget.message, borderRadius: borderRadius, isSender: false);
          case "video":
            return VideoMessageBubble(message: widget.message, borderRadius: borderRadius, isSender: false);
          default:
            return const SizedBox();
        }
      },
    );

    bool showAvatar = isLastInGroup || widget.isLastInConversation;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.grey[300],
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: senderImageUrl ?? '',
                      fit: BoxFit.cover,
                      width: 30,
                      height: 30,
                      placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => const Icon(Icons.error, size: 20),
                    ),
                  ),
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.replyToStoryUrl != null)
                    ReplyToStoryBubble(storyUrl: widget.message.replyToStoryUrl!),
                  FocusedMenuHolder(
                    menuOffset: 8,
                    onPressed: () {},
                    menuWidth: MediaQuery.of(context).size.width * 0.48,
                    blurSize: 5.0,
                    leftSide: 0,
                    rightSide: 50,
                    menuBoxDecoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    animateMenuItems: true,
                    duration: const Duration(milliseconds: 300),
                    menuItems: [
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text(
                          "Sent at ${DateFormat('dd MMM hh:mm a').format(widget.message.timestamp)}",
                          style: TextStyle(color: textColor),
                        ),
                        onPressed: () {},
                      ),
                      if (widget.message.contentType == "text")
                        FocusedMenuItem(
                          backgroundColor: menuBg,
                          title: Text("Copy text", style: TextStyle(color: textColor)),
                          trailingIcon: Icon(EvaIcons.copy, color: iconColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.message.content));
                            Get.snackbar("Copied", "Message copied to clipboard");
                          },
                        ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text("Delete for me", style: TextStyle(color: textColor)),
                        trailingIcon: Icon(EvaIcons.trashOutline, color: iconColor),
                        onPressed: () => chatController.deleteMessageLocally(widget.message.id),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text("Delete for everyone", style: TextStyle(color: Colors.red)),
                        trailingIcon: Icon(EvaIcons.trash2Outline, color: Colors.red),
                        onPressed: () => chatController.deleteMessageForAll(widget.message.id),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text("Forward", style: TextStyle(color: textColor)),
                        trailingIcon: Icon(EvaIcons.arrowForwardOutline, color: iconColor),
                        onPressed: () => chatController.forwardMessage(widget.message),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text("Reply", style: TextStyle(color: textColor)),
                        trailingIcon: Icon(EvaIcons.arrowheadUpOutline, color: iconColor),
                        onPressed: () => chatController.replyToMessage(widget.message),
                      ),
                    ],
                    child: bubbleWidget,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
