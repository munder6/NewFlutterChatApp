import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomChatWithIcon extends StatelessWidget {
  final String senderId;
  final String receiverId;
  final TextEditingController messageController;
  final VoidCallback startRecording;

  const BottomChatWithIcon({
    Key? key,
    required this.senderId,
    required this.receiverId,
    required this.messageController,
    required this.startRecording, required void Function(bool isVideo) pickMedia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {
              // هنا ممكن تفتح picker للصور أو الفيديو
            },
          ),
          IconButton(
            icon: Icon(Icons.mic),
            onPressed: startRecording, // يبدأ التسجيل عند الضغط
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              onChanged: (value) {
                // ممكن تفعيل بعض الإجراءات هنا مثل إرسال الكتابة أو تغيير الحالة
              },
              decoration: InputDecoration(
                hintText: "Type a message",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20)),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blueAccent),
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                // هنا يتم إرسال النص
                // chatController.sendMessage(senderId, receiverId, messageController.text, 'text');
                messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
