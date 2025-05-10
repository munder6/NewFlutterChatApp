import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';

class VideoViewController extends GetxController {
  late VideoPlayerController videoPlayerController;
  RxBool isControlsVisible = true.obs;
  RxBool isInitialized = false.obs;

  void init(String videoUrl) async {
    try {
      final file = await _getOrDownloadCachedVideo(videoUrl);

      videoPlayerController = VideoPlayerController.file(file);

      await videoPlayerController.initialize();
      videoPlayerController.setLooping(true);
      isInitialized.value = true;

      videoPlayerController.addListener(() {
        // لتحديث الواجهة تلقائيًا وقت تغير الحالة
        isInitialized.refresh();
      });
    } catch (e) {
      print("❌ فشل تحميل أو تهيئة الفيديو: $e");
    }
  }

  Future<File> _getOrDownloadCachedVideo(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = md5.convert(utf8.encode(url)).toString() + '.mp4';
    final filePath = '${dir.path}/$filename';
    final file = File(filePath);

    if (await file.exists()) {
      print("✅ الفيديو موجود محلياً: $filePath");
      return file;
    }

    print("⬇️ تحميل الفيديو لأول مرة...");
    final response = await Dio().download(url, filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print("Progress: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        });

    if (response.statusCode == 200) {
      print("✅ تم تخزين الفيديو محلياً: $filePath");
      return file;
    } else {
      throw Exception("❌ فشل تحميل الفيديو");
    }
  }

  void toggleControls() {
    isControlsVisible.value = !isControlsVisible.value;
  }

  void playPause() {
    if (videoPlayerController.value.isPlaying) {
      videoPlayerController.pause();
    } else {
      videoPlayerController.play();
    }
  }

  void seekTo(Duration position) {
    videoPlayerController.seekTo(position);
  }

  void rewind10Seconds() {
    final current = videoPlayerController.value.position;
    seekTo(current - const Duration(seconds: 10));
  }

  void forward10Seconds() {
    final current = videoPlayerController.value.position;
    seekTo(current + const Duration(seconds: 10));
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void onClose() {
    videoPlayerController.dispose();
    super.onClose();
  }
}
