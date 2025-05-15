import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/chat_controller.dart';
import '../modals.dart';
import '../models/message_model.dart';
import '../widgets/reply_to_story_bubble.dart';
import '../widgets/text_message_bubble.dart';
import '../widgets/video_message_bubble.dart';
import '../widgets/audio_message_bubble.dart';
import '../widgets/image_message_bubble.dart';
import '../focused_menu.dart';

class ReceiverMessageCard extends StatelessWidget {
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

  bool _hasTimeGap(DateTime prev, DateTime current) {
    return current.difference(prev).inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final menuBg = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final chatController = Get.find<ChatController>();

    final isFirstInGroup = previousMessage == null ||
        previousMessage!.senderId != message.senderId ||
        _hasTimeGap(previousMessage!.timestamp, message.timestamp);

    final isLastInGroup = nextMessage == null ||
        nextMessage!.senderId != message.senderId ||
        _hasTimeGap(message.timestamp, nextMessage!.timestamp);

    final showAvatar = isLastInGroup || isLastInConversation;

    final borderRadius = switch ((isFirstInGroup, isLastInGroup)) {
      (true, true) => BorderRadius.circular(20),
      (true, false) => const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(20),
      ),
      (false, true) => const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      _ => const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(20),
      ),
    };

    final imageUrl = chatController.senderImageCache[message.senderId];

    final bubbleWidget = switch (message.contentType) {
      "text" => TextMessageBubble(message: message, borderRadius: borderRadius, isSender: false),
      "image" => ImageMessageBubble(message: message, borderRadius: borderRadius, isSender: false),
      "audio" => AudioMessageBubble(message: message, borderRadius: borderRadius, isSender: false),
      "video" => VideoMessageBubble(message: message, borderRadius: borderRadius, isSender: false),
      _ => const SizedBox(),
    };

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
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        width: 30,
                        height: 30,
                        child: ColoredBox(color: Colors.transparent),
                      ),
                      errorWidget: (_, __, ___) => const Icon(Icons.error, size: 20),
                    )
                        : const Icon(Icons.person, size: 20),
                  ),
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyToStoryUrl != null)
                    ReplyToStoryBubble(storyUrl: message.replyToStoryUrl!),
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
                          "Received at ${DateFormat('dd MMM hh:mm a').format(message.timestamp.toLocal())}",
                          style: TextStyle(color: textColor, fontSize: 12),
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
                        onPressed: () => chatController.deleteMessageLocally(
                          message.id,
                          message.receiverId,
                        ),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text("Forward", style: TextStyle(color: textColor)),
                        trailingIcon: Icon(EvaIcons.arrowForwardOutline, color: iconColor),
                        onPressed: () => chatController.forwardMessage(message),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: Text("Reply", style: TextStyle(color: textColor)),
                        trailingIcon: Icon(EvaIcons.arrowheadUpOutline, color: iconColor),
                        onPressed: () => chatController.replyToMessage(message),
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
