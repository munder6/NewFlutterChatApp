import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/chat_controller.dart';
import '../models/message_model.dart';
import 'sender_message_card.dart';
import 'reciver_message_card.dart';

class MessageList extends StatefulWidget {
  final String currentUserId;

  const MessageList({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ChatController chatController = Get.find<ChatController>();
  bool imagesPreloaded = false;
  late Worker messageListener;


  @override
  void initState() {
    super.initState();

    // مراقبة الرسائل مرة واحدة فقط
    messageListener = ever(chatController.messages, (_) {
      if (mounted) _preloadImages();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !imagesPreloaded) {
        await chatController.preloadSenderImages(chatController.messages);
        if (mounted) {
          setState(() => imagesPreloaded = true);
        }
      }
    });
  }

  Future<void> _preloadImages() async {
    if (!imagesPreloaded && chatController.messages.isNotEmpty) {
      await chatController.preloadSenderImages(chatController.messages);
      if (mounted) {
        setState(() => imagesPreloaded = true);
      }
    }
  }
  @override
  void dispose() {
    messageListener.dispose(); // مهم: إيقاف الاستماع بعد الخروج
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = chatController.messages.reversed.toList();

      if (messages.isEmpty) {
        return const Center(
          child: Text("No messages yet..."),
        );
      }

      int? lastReadIndex;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].senderId == widget.currentUserId && messages[i].isRead) {
          lastReadIndex = i;
          break;
        }
      }

      bool receiverSentAfterRead = false;
      if (lastReadIndex != null) {
        for (int j = 0; j < lastReadIndex; j++) {
          if (messages[j].senderId != widget.currentUserId) {
            receiverSentAfterRead = true;
            break;
          }
        }
      }

      return ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final prev = index < messages.length - 1 ? messages[index + 1] : null;
          final next = index > 0 ? messages[index - 1] : null;

          final isSender = msg.senderId == widget.currentUserId;
          final currentSender = msg.senderId;
          final nextSender = next?.senderId;

          bool timeGapExists = false;
          String? nextMessageTime;
          if (prev != null) {
            timeGapExists = _hasTimeGap(prev.timestamp, msg.timestamp);
            if (timeGapExists) {
              nextMessageTime = _formatTimestamp(msg.timestamp);
            }
          }

          if (msg.contentType == "video") {
            chatController.generateAndCacheThumbnail(msg.content).then((_) {
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            });
          }

          final isLastInConversation = index == 0 ||
              (next != null && next.senderId != msg.senderId) ||
              (next != null && _hasTimeGap(msg.timestamp, next.timestamp));

          final bool showSeenIndicator = isSender &&
              msg.isRead &&
              index == lastReadIndex &&
              !receiverSentAfterRead;

          return Column(
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (timeGapExists) _buildTimeCard(nextMessageTime),
              isSender
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SenderMessageCard(
                    message: msg,
                    previousMessage: prev,
                    nextMessage: next,
                  ),
                  if (showSeenIndicator)
                    Padding(
                      padding: const EdgeInsets.only(right: 22, top: 2),
                      child: Text(
                        'Seen',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              )
                  : Padding(
                padding: EdgeInsets.only(
                  left: isLastInConversation ? 0 : 38,
                ),
                child: ReceiverMessageCard(
                  message: msg,
                  previousMessage: prev,
                  nextMessage: next,
                  isLastInConversation: isLastInConversation,
                ),
              ),
              if (next != null && nextSender != currentSender)
                const SizedBox(height: 10),
            ],
          );
        },
      );
    });
  }

  bool _hasTimeGap(DateTime prevTime, DateTime currentTime) {
    return currentTime.difference(prevTime).inMinutes > 5;
  }

  Widget _buildTimeCard(String? nextMessageTime) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          nextMessageTime!,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('dd MMM yyyy – hh:mm a').format(timestamp);
  }
}
