
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'dart:ui' as ui;

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
      borderRadius = BorderRadius.circular(20);
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
                    "Sent at ${DateFormat('dd MMM hh:mm a').format(message.timestamp.toLocal())}",
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
                  onPressed: () => chatController.deleteMessageLocally(message.id, message.receiverId),
                ),
                FocusedMenuItem(
                  backgroundColor: menuBg,
                  title: Text("Delete for everyone", style: TextStyle(color: Colors.red)),
                  trailingIcon: Icon(EvaIcons.trash2Outline, color: Colors.red),
                  onPressed: () => chatController.deleteMessageForAll(message.id, message.receiverId),
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditMessageDialog(message: message),
                      );
                    },                  ),
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


class EditMessageDialog extends StatefulWidget {
  final MessageModel message;

  const EditMessageDialog({super.key, required this.message});

  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late TextEditingController _controller;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  ui.TextDirection _getTextDirection(String text) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;
  }

  TextAlign _getTextAlign(String text) {
    return _getTextDirection(text) == ui.TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platform = defaultTargetPlatform;
    final Color hintColor = isDark ? Colors.white54 : Colors.black45;

    final baseStyle = platform == TargetPlatform.iOS
        ? TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontFamily: '.SF UI Text',
      fontFamilyFallback: ['NotoColorEmoji'],
    )
        : GoogleFonts.notoSansArabic(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ).copyWith(
      fontFamilyFallback: ['NotoColorEmoji'],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                    minWidth: MediaQuery.of(context).size.width * 0.4,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Directionality(
                      textDirection: _getTextDirection(_controller.text),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        onChanged: (_) => setState(() {}),
                        textAlign: _getTextAlign(_controller.text),
                        style: baseStyle,
                        decoration: InputDecoration(
                          hintText: 'Edit message...',
                          hintStyle: baseStyle.copyWith(
                            color: hintColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                        setState(() => isSaving = true);
                        await Get.find<ChatController>().editMessage(
                          widget.message,
                          _controller.text.trim(),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text("Done", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

