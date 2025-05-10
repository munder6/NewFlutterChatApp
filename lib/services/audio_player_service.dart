import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class AudioPlayerService extends GetxService {
  final Map<String, PlayerController> _controllers = {};
  final Map<String, RxBool> _isPlaying = {};
  final Map<String, RxBool> _isReady = {};
  final Map<String, Rx<Duration>> _currentPosition = {};

  PlayerController? getControllerOrNull(String id) => _controllers[id];
  PlayerController? getController(String id) => _controllers[id];

  RxBool? isPlayingRx(String id) => _isPlaying[id];
  RxBool? isReadyRx(String id) => _isReady[id];
  Rx<Duration>? getCurrentPositionRx(String id) => _currentPosition[id];

  bool isPlaying(String id) => _isPlaying[id]?.value ?? false;
  bool isReady(String id) => _isReady[id]?.value ?? false;
  Duration getCurrentPosition(String id) => _currentPosition[id]?.value ?? Duration.zero;

  Future<void> initPlayer(MessageModel message) async {
    final id = message.id;
    if (_controllers.containsKey(id)) return;

    final controller = PlayerController();
    _controllers[id] = controller;
    _isPlaying[id] = false.obs;
    _isReady[id] = false.obs;
    _currentPosition[id] = Rx<Duration>(Duration.zero);

    final localPath = message.localPath ?? await _getCachedPath(message.content);
    if (localPath == null) return;

    try {
      await controller.preparePlayer(
        path: localPath,
        shouldExtractWaveform: true,
        noOfSamples: 200,
      );

      _isReady[id]!.value = true;

      controller.onCurrentDurationChanged.listen((ms) {
        _currentPosition[id]!.value = Duration(milliseconds: ms);
      });

      controller.onCompletion.listen((_) async {
        _isPlaying[id]!.value = false;
        _currentPosition[id]!.value = Duration.zero;

        try {
          // ❗ الحل الحقيقي: إعادة التحضير حتى يسمح بالتشغيل مرة أخرى
          await controller.preparePlayer(
            path: localPath,
            shouldExtractWaveform: false,
            noOfSamples: 200,
          );
        } catch (e) {
          print("❌ Error re-preparing player for $id after completion: $e");
        }
      });
    } catch (e) {
      print('❌ Error preparing player for $id: $e');
    }
  }

  Future<void> togglePlayback(MessageModel message) async {
    final id = message.id;

    // إذا لم يكن جاهزاً، نجهزه أولاً
    if (!_isReady.containsKey(id) || !_isReady[id]!.value) {
      await initPlayer(message);
    }

    final controller = _controllers[id];
    if (controller == null) return;

    if (_isPlaying[id]!.value) {
      await controller.pausePlayer();
      _isPlaying[id]!.value = false;
    } else {
      // وقف كل الأصوات الأخرى
      for (final entry in _controllers.entries) {
        final otherId = entry.key;
        final otherController = entry.value;
        if (otherId != id && _isPlaying[otherId]?.value == true) {
          await otherController.pausePlayer();
          _isPlaying[otherId]?.value = false;
        }
      }

      await controller.startPlayer();
      _isPlaying[id]!.value = true;
    }
  }

  Future<String?> _getCachedPath(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = md5.convert(utf8.encode(url)).toString() + '.m4a';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) return filePath;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }

      return null;
    } catch (e) {
      print("❌ Error caching audio: $e");
      return null;
    }
  }

  @override
  void onClose() {
    for (var controller in _controllers.values) {
      controller.stopPlayer();
      controller.dispose();
    }
    super.onClose();
  }
}
