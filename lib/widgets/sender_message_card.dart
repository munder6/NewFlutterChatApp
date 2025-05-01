// ✅ SenderMessageCard.dart
import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import '../controller/chat_controller.dart';
import '../models/message_model.dart';

class SenderMessageCard extends StatefulWidget {
  final MessageModel message;
  final MessageModel? previousMessage;
  final MessageModel? nextMessage;

  const SenderMessageCard({
    super.key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
  });

  @override
  State<SenderMessageCard> createState() => _SenderMessageCardState();
}

class _SenderMessageCardState extends State<SenderMessageCard> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;


  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });

    _audioPlayer.durationStream.listen((d) {
      if (d != null) setState(() => _duration = d);
    });

    _audioPlayer.positionStream.listen((p) {
      setState(() => _position = p);
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
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
      print("❌ Error playing audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    bool isFirst = widget.previousMessage == null ||
        widget.previousMessage!.senderId != widget.message.senderId ||
        _hasTimeGap(widget.previousMessage!.timestamp, widget.message.timestamp);

    bool isLast = widget.nextMessage == null ||
        widget.nextMessage!.senderId != widget.message.senderId ||
        _hasTimeGap(widget.message.timestamp, widget.nextMessage!.timestamp);

    BorderRadiusGeometry borderRadius = _getBubbleRadius(isFirst, isLast);

    Color bgColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade700
        : Colors.blue.shade400;

    // Check for time gap and add spacing if necessary
    bool timeGapExists = widget.previousMessage != null &&
        _hasTimeGap(widget.previousMessage!.timestamp, widget.message.timestamp);

    return Padding(
      padding: EdgeInsets.only(top: timeGapExists ? 15 : 1, left: 15, right: 15),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
            widget.message.contentType == "image"
                ? FutureBuilder<Size>(
              future: _getImageSize(widget.message.content),
              builder: (context, snapshot) {
                final size = snapshot.data ?? Size(200, 200);
                return GestureDetector(
                  onTap: () {
                    // عندما يتم الضغط على الصورة، يتم فتحها في نافذة منبثقة
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Dialog(
                            backgroundColor: Colors.transparent, // لجعل الخلفية شفافة
                            child: Stack(
                              children: [
                                // تأثير التمويه على الخلفية
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // تأثير التمويه
                                    child: Container(),
                                  ),
                                ),
                                // عرض الصورة المكبرة مع دعم التمرير
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.pop(context);
                                            },
                                            child: Icon(EvaIcons.close, size: 28),
                                          ),
                                          Text("Save Photo", style: TextStyle(fontSize: 18)),
                                        ],
                                      ),
                                      SizedBox(height: 25),
                                      Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: CachedNetworkImage(
                                            imageUrl: widget.message.content,
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(context).size.width,
                                            height: MediaQuery.of(context).size.height / 1.5, // ارتفاع نافذة البوب أب
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade900,
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  hintText: "Type Your Reply", // النص المساعد داخل الحقل
                                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)), // لون النص المساعد
                                                  border: InputBorder.none, // إزالة الحدود
                                                  contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // المسافات داخل TextField
                                                ),
                                                style: TextStyle(color: Colors.white), // لون النص داخل الـ TextField
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                // ضع هنا الكود الذي سيتم تنفيذه عند الضغط على زر "Send"
                                                print("Send tapped");
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                                child: Text(
                                                  "Send", // نص زر "Send"
                                                  style: TextStyle(
                                                    color: Colors.blue, // لون النص في زر "Send"
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.content,
                      width: size.width,
                      height: size.height,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: size.width,
                        height: size.height,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: size.width,
                        height: size.height,
                        color: Colors.grey,
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
            )
                : widget.message.contentType == "audio"
                ? Container(
              decoration: BoxDecoration(
                color: bgColor,
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
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      _isPlaying
                          ? await _audioPlayer.pause()
                          : await _playAudio();
                    },
                  ),
                  SizedBox(
                    width: 130,
                    child: Slider(
                      value: _duration.inMilliseconds == 0
                          ? 0
                          : (_position.inMilliseconds /
                          _duration.inMilliseconds)
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
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadius,
              ),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              child: Text(
                widget.message.content,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasTimeGap(Timestamp prevTime, Timestamp currentTime) {
    DateTime prev = prevTime.toDate();
    DateTime curr = currentTime.toDate();
    return curr.difference(prev).inMinutes > 5;
  }

  BorderRadiusGeometry _getBubbleRadius(bool isFirst, bool isLast) {
    if (isFirst && isLast) return BorderRadius.circular(50);
    if (isFirst) {
      return BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      return BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(5),
      );
    }
  }
}

Future<Size> _getImageSize(String url) async {
  final Completer<Size> completer = Completer();
  final Image image = Image.network(url);
  image.image.resolve(ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      var size = Size(
        info.image.width.toDouble().clamp(100, 250),
        info.image.height.toDouble().clamp(100, 300),
      );
      completer.complete(size);
    }),
  );
  return completer.future;
}




