import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meassagesapp/controller/chat_controller.dart';
import 'package:meassagesapp/widgets/video_player.dart';
import '../../models/message_model.dart';

class VideoMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isSender;
  final BorderRadiusGeometry borderRadius;

  const VideoMessageBubble({
    super.key,
    required this.message,
    required this.borderRadius,
    required this.isSender,
  });

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final String? thumbnailPath = chatController.videoThumbnails[widget.message.content];

    final double maxWidth = MediaQuery.of(context).size.width * 0.3;
    final double fallbackAspectRatio = 9 / 16;

    return GestureDetector(
      onTap: () {
        final videoPath = (widget.message.localPath != null &&
            File(widget.message.localPath!).existsSync())
            ? widget.message.localPath!
            : widget.message.content;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoViewPage(videoUrl: videoPath),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: (thumbnailPath != null && File(thumbnailPath).existsSync())
            ? AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(thumbnailPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
              ),
            ],
          ),
        )
            : AspectRatio(
          aspectRatio: fallbackAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }
}
