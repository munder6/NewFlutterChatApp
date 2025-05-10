import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:meassagesapp/widgets/reciver_message_card.dart';
import '../controller/chat_controller.dart';
import '../models/message_model.dart';
import 'sender_message_card.dart';

class MessageList extends StatelessWidget {
  final List<MessageModel> messages;
  final String currentUserId;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    // Find the last read message index for current user
    int? lastReadIndex;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].senderId == currentUserId && messages[i].isRead) {
        lastReadIndex = i;
        break; // First read from top (since ListView is reversed)
      }
    }

    // Check if receiver sent a message after the last read one
    bool receiverSentAfterRead = false;
    if (lastReadIndex != null) {
      for (int j = 0; j < lastReadIndex; j++) {
        if (messages[j].senderId != currentUserId) {
          receiverSentAfterRead = true;
          break;
        }
      }
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 110, top: 110),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prev = index < messages.length - 1 ? messages[index + 1] : null;
        final next = index > 0 ? messages[index - 1] : null;

        final isSender = msg.senderId == currentUserId;
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
            (context as Element).markNeedsBuild();
          });
        }

        final isLastInConversation =
            index == 0 ||
                (next != null && next.senderId != msg.senderId) ||
                (next != null && _hasTimeGap(msg.timestamp, next.timestamp));

        final bool showSeenIndicator =
            isSender &&
                msg.isRead &&
                index == lastReadIndex &&
                !receiverSentAfterRead;

        return Column(
          crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                          color: Colors.grey.shade600),
                    ),
                  )
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
              SizedBox(height: 10),
          ],
        );
      },
    );
  }

  bool _hasTimeGap(DateTime prevTime, DateTime currentTime) {
    return currentTime.difference(prevTime).inMinutes > 5;
  }

  Widget _buildTimeCard(String? nextMessageTime) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 15),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
