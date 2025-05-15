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
  RxBool? isPlayingRx(String id) => _isPlaying[id];
  RxBool? isReadyRx(String id) => _isReady[id];
  Rx<Duration>? getCurrentPositionRx(String id) => _currentPosition[id];
  bool isReady(String id) => _isReady[id]?.value ?? false;

  Future<void> initPlayer(MessageModel message) async {
    final id = message.id;
    if (_controllers.containsKey(id) && isReady(id)) return;

    final controller = PlayerController();
    _controllers[id] = controller;
    _isPlaying[id] = false.obs;
    _isReady[id] = false.obs;
    _currentPosition[id] = Rx(Duration.zero);

    final localPath = message.localPath ?? await _cacheAudio(message);
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
          await controller.preparePlayer(
            path: localPath,
            shouldExtractWaveform: false,
            noOfSamples: 200,
          );
        } catch (_) {}
      });
    } catch (e) {
      print('❌ preparePlayer error: $e');
    }
  }

  Future<void> togglePlayback(MessageModel message) async {
    final id = message.id;
    if (!isReady(id)) await initPlayer(message);

    final controller = _controllers[id];
    if (controller == null) return;

    if (_isPlaying[id]!.value) {
      await controller.pausePlayer();
      _isPlaying[id]!.value = false;
    } else {
      for (final entry in _controllers.entries) {
        if (entry.key != id && _isPlaying[entry.key]?.value == true) {
          await entry.value.pausePlayer();
          _isPlaying[entry.key]!.value = false;
        }
      }
      await controller.startPlayer();
      _isPlaying[id]!.value = true;
    }
  }

  Future<String?> _cacheAudio(MessageModel message) async {
    try {
      final url = message.content;
      final dir = await getApplicationDocumentsDirectory();
      final fileName = md5.convert(utf8.encode(url)).toString() + '.m4a';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) return filePath;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        message.localPath = filePath; // 🔥 احفظ المسار مباشرة
        return filePath;
      }
    } catch (e) {
      print("❌ cache error: $e");
    }
    return null;
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
