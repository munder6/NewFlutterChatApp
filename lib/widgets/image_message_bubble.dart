import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/message_model.dart';
import '../services/cach_manager.dart';

class ImageMessageBubble extends StatelessWidget {
  final MessageModel message;
  final BorderRadiusGeometry borderRadius;
  final bool isSender;

  const ImageMessageBubble({
    Key? key,
    required this.message,
    required this.borderRadius,
    required this.isSender,
  }) : super(key: key);

  static const double _fallbackAspectRatio = 9 / 16;

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.3;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(),
                  ),
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: message.content,
                      cacheManager: CustomImageCacheManager.instance,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => AspectRatio(
                        aspectRatio: _fallbackAspectRatio,
                        child: Container(
                          width: maxWidth,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      errorWidget: (context, url, error) => AspectRatio(
                        aspectRatio: _fallbackAspectRatio,
                        child: Container(
                          width: maxWidth,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.error)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
      child: message.localPath != null && File(message.localPath!).existsSync()
          ? Image.file(
        File(message.localPath!),
        fit: BoxFit.cover,
      )
          : CachedNetworkImage(
        imageUrl: message.content,
        cacheManager: CustomImageCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (context, url) => AspectRatio(
          aspectRatio: _fallbackAspectRatio,
          child: Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
        errorWidget: (context, url, error) => AspectRatio(
          aspectRatio: _fallbackAspectRatio,
          child: Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error)),
          ),
        ),
      ),
    ),
      ),
    );
  }
}
