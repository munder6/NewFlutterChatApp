import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/chat_controller.dart';
import '../focused_menu.dart';
import '../modals.dart';
import '../models/message_model.dart';
import 'audio_message_bubble.dart';
import 'image_message_bubble.dart';
import 'reply_to_story_bubble.dart';
import 'text_message_bubble.dart';
import 'video_message_bubble.dart';

class SenderMessageCard extends StatelessWidget {
  final MessageModel message;
  final MessageModel? previousMessage;
  final MessageModel? nextMessage;

  const SenderMessageCard({
    super.key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
  });

  bool _hasTimeGap(DateTime prev, DateTime current) {
    return current.difference(prev).inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color iconColor = isDark ? Colors.white70 : Colors.black87;
    final Color menuBg = isDark ? Colors.grey.shade900 : Colors.grey.shade200;

    bool isFirstInGroup = previousMessage == null ||
        previousMessage!.senderId != message.senderId ||
        _hasTimeGap(previousMessage!.timestamp, message.timestamp);

    bool isLastInGroup = nextMessage == null ||
        nextMessage!.senderId != message.senderId ||
        _hasTimeGap(message.timestamp, nextMessage!.timestamp);

    final ChatController chatController = Get.find<ChatController>();

    BorderRadiusGeometry borderRadius;
    if (isFirstInGroup && isLastInGroup) {
      borderRadius = BorderRadius.circular(50);
    } else if (isFirstInGroup) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(5),
      );
    } else if (isLastInGroup) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    } else {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(5),
      );
    }

    Widget bubble;
    switch (message.contentType) {
      case "text":
        bubble = TextMessageBubble(message: message, borderRadius: borderRadius, isSender: true);
        break;
      case "image":
        bubble = ImageMessageBubble(message: message, borderRadius: borderRadius, isSender: true);
        break;
      case "audio":
        bubble = AudioMessageBubble(message: message, borderRadius: borderRadius, isSender: true);
        break;
      case "video":
        bubble = VideoMessageBubble(message: message, borderRadius: borderRadius, isSender: true);
        break;
      default:
        bubble = const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.replyToStoryUrl != null)
              ReplyToStoryBubble(storyUrl: message.replyToStoryUrl!),
            FocusedMenuHolder(
              menuOffset: 8,
              onPressed: () {},
              menuWidth: MediaQuery.of(context).size.width * 0.55,
              blurSize: 5.0,
              leftSide: 0,
              rightSide: MediaQuery.of(context).size.width / 2.07,
              menuBoxDecoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              animateMenuItems: true,
              duration: const Duration(milliseconds: 200),
              menuItems: [
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text(
                    "Sent at ${DateFormat('dd MMM hh:mm a').format(message.timestamp)}",
                    style: TextStyle(color: textColor),
                  ),
                  onPressed: () {},
                ),
                if (message.contentType == "text")
                  FocusedMenuItem(
                    backgroundColor: menuBg,
                    title: Text("Copy text", style: TextStyle(color: textColor)),
                    trailingIcon: Icon(EvaIcons.copy, color: iconColor),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      Get.snackbar("Copied", "Message copied to clipboard");
                    },
                  ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Delete for me", style: TextStyle(color: textColor)),
                  trailingIcon: Icon(EvaIcons.trashOutline, color: iconColor),
                  onPressed: () => chatController.deleteMessageLocally(message.id),
                ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Delete for everyone", style: TextStyle(color: Colors.red)),
                  trailingIcon: Icon(EvaIcons.trash2Outline, color: Colors.red),
                  onPressed: () => chatController.deleteMessageForAll(message.id),
                ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Forward", style: TextStyle(color: textColor)),
                  trailingIcon: Icon(EvaIcons.arrowForwardOutline, color: iconColor),
                  onPressed: () => chatController.forwardMessage(message),
                ),
                if (message.contentType == "text")
                  FocusedMenuItem(
                    backgroundColor: menuBg,
                    title: Text("Edit", style: TextStyle(color: textColor)),
                    trailingIcon: Icon(EvaIcons.edit2Outline, color: iconColor),
                    onPressed: () => chatController.editMessage(message),
                  ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Reply", style: TextStyle(color: textColor)),
                  trailingIcon: Icon(EvaIcons.arrowheadUpOutline, color: iconColor),
                  onPressed: () => chatController.replyToMessage(message),
                ),
              ],
              child: bubble,
            ),
          ],
        ),
      ),
    );
  }
}
