import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailCache {
  static final VideoThumbnailCache _instance = VideoThumbnailCache._internal();
  factory VideoThumbnailCache() => _instance;
  VideoThumbnailCache._internal();

  final Map<String, String> _memoryCache = {};
  final GetStorage _storage = GetStorage();

  String _generateSafeFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<String?> getThumbnail(String videoUrl) async {
    // Step 1: check in-memory cache
    if (_memoryCache.containsKey(videoUrl)) {
      return _memoryCache[videoUrl];
    }

    // Step 2: check persistent cache
    final storedPath = _storage.read(videoUrl);
    if (storedPath != null && File(storedPath).existsSync()) {
      _memoryCache[videoUrl] = storedPath;
      return storedPath;
    }

    // Step 3: generate new thumbnail
    final dir = await getTemporaryDirectory();
    final fileName = _generateSafeFileName(videoUrl);
    final thumbPath = '${dir.path}/thumb_$fileName.jpg';

    final generatedPath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: thumbPath,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );

    if (generatedPath != null) {
      _storage.write(videoUrl, generatedPath);
      _memoryCache[videoUrl] = generatedPath;
      return generatedPath;
    }

    return null;
  }
}
