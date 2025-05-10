import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meassagesapp/controller/video_player_controller.dart';
import 'package:video_player/video_player.dart';

class VideoViewPage extends StatefulWidget {
  final String videoUrl;

  const VideoViewPage({super.key, required this.videoUrl});

  @override
  State<VideoViewPage> createState() => _VideoViewPageState();
}

class _VideoViewPageState extends State<VideoViewPage> {
  final controller = Get.put(VideoViewController());

  @override
  void initState() {
    super.initState();
    controller.init(widget.videoUrl);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (!controller.isInitialized.value ||
              !controller.videoPlayerController.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.toggleControls,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.videoPlayerController.value.aspectRatio,
                    child: VideoPlayer(controller.videoPlayerController),
                  ),
                ),

                if (controller.isControlsVisible.value)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _iconButton(
                              icon: CupertinoIcons.gobackward_10,
                              onTap: controller.rewind10Seconds,
                            ),
                            const SizedBox(width: 30),
                            _iconButton(
                              icon: controller.videoPlayerController.value.isPlaying
                                  ? CupertinoIcons.pause_circle_fill
                                  : CupertinoIcons.play_circle_fill,
                              size: 60,
                              onTap: controller.playPause,
                            ),
                            const SizedBox(width: 30),
                            _iconButton(
                              icon: CupertinoIcons.goforward_10,
                              onTap: controller.forward10Seconds,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              controller.formatDuration(
                                controller.videoPlayerController.value.position,
                              ),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Expanded(
                              child: Slider(
                                value: controller.videoPlayerController.value.position.inMilliseconds
                                    .toDouble(),
                                min: 0,
                                max: controller.videoPlayerController.value.duration.inMilliseconds
                                    .toDouble(),
                                activeColor: Colors.white,
                                inactiveColor: Colors.white30,
                                onChanged: (value) {
                                  controller.seekTo(Duration(milliseconds: value.toInt()));
                                },
                              ),
                            ),
                            Text(
                              controller.formatDuration(
                                controller.videoPlayerController.value.duration,
                              ),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 30,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
