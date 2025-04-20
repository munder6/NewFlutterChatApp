import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class RecordingMic extends StatelessWidget {
  final Duration recordingDuration;
  final VoidCallback stopRecording;

  const RecordingMic({
    Key? key,
    required this.recordingDuration,
    required this.stopRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.stop, color: Colors.white, size: 30),
            onPressed: stopRecording, // عند الضغط يتوقف التسجيل
          ),
          SizedBox(height: 10),
          Text(
            '${recordingDuration.inSeconds}s',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
