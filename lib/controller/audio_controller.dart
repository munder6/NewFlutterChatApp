import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class AudioController {
  final RecorderController recorderController = RecorderController();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  String? _audioPath;

  /// Initializes recorder with proper encoder and path
  Future<void> initRecorder() async {
    final tempDir = await getTemporaryDirectory();
    _audioPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    recorderController.androidEncoder = AndroidEncoder.aac;
    recorderController.androidOutputFormat = AndroidOutputFormat.mpeg4;
    recorderController.iosEncoder = IosEncoder.kAudioFormatMPEG4AAC;
    recorderController.sampleRate = 16000;
  }

  /// Starts recording to temporary path
  Future<void> startRecording() async {
    if (_audioPath == null) await initRecorder();
    await recorderController.record(path: _audioPath!);
  }

  /// Stops recording and uploads file to Firebase
  Future<void> stopRecordingAndUpload({
    required String senderId,
    required String receiverId,
    required Function(String url) onSend,
  }) async {
    final path = await recorderController.stop();
    if (path == null || path.isEmpty) return;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _firebaseStorage.ref().child('audio_messages/$fileName');

    await ref.putFile(File(path), SettableMetadata(contentType: 'audio/mp4'));
    final downloadUrl = await ref.getDownloadURL();
    onSend(downloadUrl);
  }

  /// Call when widget disposed
  void dispose() {
    recorderController.dispose();
  }
}
