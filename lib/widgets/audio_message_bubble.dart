import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../models/message_model.dart';
import '../services/audio_player_service.dart';

class AudioMessageBubble extends StatefulWidget {
  final MessageModel message;
  final BorderRadiusGeometry borderRadius;
  final bool isSender;

  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.borderRadius,
    required this.isSender,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  late final AudioPlayerService _audioService;
  late final String _messageId;

  bool isWaveformLoaded = false;

  @override
  void initState() {
    super.initState();
    _audioService = Get.find<AudioPlayerService>();
    _messageId = widget.message.id;

    final existing = _audioService.getControllerOrNull(_messageId);
    if (existing != null && _audioService.isReady(_messageId)) {
      isWaveformLoaded = true;
      return;
    }

    Future.microtask(() async {
      await _audioService.initPlayer(widget.message);
      final controller = _audioService.getControllerOrNull(_messageId);
      if (controller != null) {
        while (controller.waveformData == null) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (mounted) {
          setState(() => isWaveformLoaded = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlayingRx = _audioService.isPlayingRx(_messageId);
    final isReadyRx = _audioService.isReadyRx(_messageId);
    final positionRx = _audioService.getCurrentPositionRx(_messageId);
    final controller = _audioService.getControllerOrNull(_messageId);

    return Container(
      decoration: BoxDecoration(
        gradient: widget.isSender
            ? LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [Colors.grey.shade900, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: widget.borderRadius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.55,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isPlayingRx != null)
            Obx(() {
              return GestureDetector(
                onTap: () => _audioService.togglePlayback(widget.message),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(
                    isPlayingRx.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            }),

          const SizedBox(width: 6),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: isWaveformLoaded && controller != null
                  ? AnimatedOpacity(
                opacity: isWaveformLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: AudioFileWaveforms(
                  key: const ValueKey('waveform'), // مهم حتى AnimatedSwitcher يشتغل صح
                  size: const Size(double.infinity, 36),
                  playerController: controller,
                  enableSeekGesture: true,
                  waveformType: WaveformType.long,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: Colors.white.withOpacity(0.5),
                    liveWaveColor: Colors.white,
                    waveCap: StrokeCap.round,
                    spacing: 4,
                    scaleFactor: 50,
                  ),
                ),
              )
                  : Container(
                key: const ValueKey('loading'),
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const CupertinoActivityIndicator(radius: 10),
              ),
            ),
          ),


          const SizedBox(width: 6),

          if (positionRx != null)
            Obx(() {
              return Text(
                _formatDuration(positionRx.value),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
