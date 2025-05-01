import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meassagesapp/widgets/reciver_message_card.dart';
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
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prev = index < messages.length - 1 ? messages[index + 1] : null;
        final next = index > 0 ? messages[index - 1] : null;

        final isSender = msg.senderId == currentUserId;
        final currentSender = msg.senderId;
        final nextSender = next?.senderId;


        // Calculate if there's a time gap of more than 5 minutes between messages
        bool timeGapExists = false;
        String? nextMessageTime;
        if (prev != null) {
          timeGapExists = _hasTimeGap(prev.timestamp, msg.timestamp);
          // Set the time of the next message if the time gap exists
          if (timeGapExists) {
            nextMessageTime = _formatTimestamp(msg.timestamp);
          }
        }

        return Column(
          children: [
            // Insert time card if there's a time gap
            if (timeGapExists) _buildTimeCard(nextMessageTime),
            // Render message cards
            isSender
                ? SenderMessageCard(
              message: msg,
              previousMessage: prev,
              nextMessage: next,
            )
                : ReceiverMessageCard(
              message: msg,
              previousMessage: prev,
              nextMessage: next,
            ),
            // Add space between messages if the sender changes
            if (next != null && nextSender != currentSender)
              SizedBox(height: 5), // المسافة بين الرسائل بعد فارق الزمن
          ],
        );
      },
    );
  }

  // Method to check for time gap
  bool _hasTimeGap(Timestamp prevTime, Timestamp currentTime) {
    DateTime prev = prevTime.toDate();  // تحويل Timestamp إلى DateTime
    DateTime curr = currentTime.toDate();  // تحويل Timestamp إلى DateTime
    return curr.difference(prev).inMinutes > 5;  // تحقق إذا كان الفارق الزمني أكثر من 5 دقائق
  }

  // Method to build the time card widget
  Widget _buildTimeCard(String? nextMessageTime) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      // decoration: BoxDecoration(
      //   color: Colors.grey.shade300,
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: Text(
        nextMessageTime!,  // إذا كان الوقت موجود نعرضه، إذا لا نعرض "Time Gap"
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Format timestamp to a human-readable time
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();  // تحويل Timestamp إلى DateTime
    return DateFormat('dd MMM yyyy – hh:mm a').format(dateTime);  // تنسيق الوقت ليكون في شكل "يوم، شهر، سنة، وقت AM/PM"
  }
}
