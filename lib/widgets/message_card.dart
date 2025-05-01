import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import '../models/message_model.dart';

class MessageCard extends StatefulWidget {
  final MessageModel message;
  final MessageModel? previousMessage;
  final MessageModel? nextMessage;
  final bool isSender;

  const MessageCard({
    super.key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
    required this.isSender,
  });

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {

        _isPlaying = state.playing;

    });

    _audioPlayer.durationStream.listen((d) {
      if (d != null) {

          _duration = d;

      }
    });

    _audioPlayer.positionStream.listen((p) {

        _position = p;

    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {

          _isPlaying = false;
          _position = Duration.zero;

      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.setUrl(widget.message.content);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFirstInGroup = widget.previousMessage == null ||
        widget.previousMessage!.senderId != widget.message.senderId ||
        _hasTimeGap(widget.previousMessage!.timestamp, widget.message.timestamp);

    bool isLastInGroup = widget.nextMessage == null ||
        widget.nextMessage!.senderId != widget.message.senderId ||
        _hasTimeGap(widget.message.timestamp, widget.nextMessage!.timestamp);

    BorderRadiusGeometry borderRadius;
    if (isFirstInGroup && isLastInGroup) {
      borderRadius = BorderRadius.circular(50);
    } else if (isFirstInGroup) {
      borderRadius = BorderRadius.only(
        topLeft: widget.isSender ? const Radius.circular(20) : const Radius.circular(5),
        topRight: widget.isSender ? const Radius.circular(5) : const Radius.circular(20),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
      );
    } else if (isLastInGroup) {
      borderRadius = BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: widget.isSender ? const Radius.circular(20) : const Radius.circular(5),
        bottomRight: widget.isSender ? const Radius.circular(5) : const Radius.circular(20),
      );
    } else {
      borderRadius = BorderRadius.only(
        topLeft: widget.isSender ? const Radius.circular(20) : const Radius.circular(5),
        topRight: widget.isSender ? const Radius.circular(5) : const Radius.circular(20),
        bottomLeft: widget.isSender ? const Radius.circular(20) : const Radius.circular(5),
        bottomRight: widget.isSender ? const Radius.circular(5) : const Radius.circular(20),
      );
    }

    Color messageColor = widget.isSender
        ? (Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade700
        : Colors.blue.shade400)
        : (Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200);

    Color textColor = widget.isSender
        ? Colors.white
        : (Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black);

    final box = GetStorage();
    final String currentUserId = box.read('user_id') ?? '';

    return Padding(
      padding: EdgeInsets.only(top: 0.8, left: 15, right: 15),
      child: Align(
        alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (widget.message.replyToStoryUrl != null)
              Container(
                margin: EdgeInsets.only(bottom: 5),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(widget.message.replyToStoryUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      "رد على ستوري",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ الرسالة الأساسية
            widget.message.contentType == "image"
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.message.content,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
                : widget.message.contentType == "audio"
                ? Container(
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: borderRadius,
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isSender ? Colors.white : Colors.black,
                    ),
                    onPressed: () async {
                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        await _playAudio();
                      }
                    },
                  ),
                  SizedBox(
                    width: 130,
                    child: Slider(
                      value: _duration.inMilliseconds == 0
                          ? 0
                          : (_position.inMilliseconds / _duration.inMilliseconds)
                          .clamp(0.0, 1.0),
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        final newPos = _duration * value;
                        _audioPlayer.seek(newPos);
                      },
                    ),
                  ),
                  Text(
                    "${_position.inMinutes}:${_position.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: widget.isSender ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: borderRadius,
              ),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              child: Text(
                widget.message.content,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasTimeGap(Timestamp prevTime, Timestamp currentTime) {
    DateTime prevDateTime = prevTime.toDate();
    DateTime currentDateTime = currentTime.toDate();
    return currentDateTime.difference(prevDateTime).inMinutes > 5;
  }
}
