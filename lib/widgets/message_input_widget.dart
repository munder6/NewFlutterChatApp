// ✅ هذا هو الكود الكامل لـ MessageInputWidget بعد دمج FocusedMenuHolder مع زر الورقة
import 'dart:async';
import 'dart:ui';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/audio_controller.dart';
import '../controller/chat_controller.dart';
import '../focused_menu.dart';
import '../modals.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendAudio;
  final AudioController audioController;

  final Function(ImageSource source, bool isVideo) onMediaPick;

  const MessageInputWidget({
    super.key,
    required this.onSendText,
    required this.onSendAudio,
    required this.audioController,
    required this.onMediaPick,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatController chatController = Get.find();
  final String userId = GetStorage().read('user_id') ?? '';
  Timer? _typingTimer;

  bool _showSend = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPreview = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    widget.audioController.initRecorder();

    _controller.addListener(() {
      final isTyping = _controller.text.trim().isNotEmpty;
      setState(() => _showSend = isTyping);
      _updateTypingStatus(isTyping);
    });
  }

  void _updateTypingStatus(bool isTyping) {
    if (userId.isEmpty) return;

    _typingTimer?.cancel();

    if (isTyping) {
      _firestore.collection('users').doc(userId).update({'isTyping': true});
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _firestore.collection('users').doc(userId).update({'isTyping': false});
      });
    } else {
      _firestore.collection('users').doc(userId).update({'isTyping': false});
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      _controller.clear();
      _updateTypingStatus(false);
    }
  }

  void _startTimer() {
    _recordDuration = Duration.zero;
    _recordTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final containerColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;

    return _isRecording || _isPreview
        ? _buildRecordingUI(containerColor, iconColor)
        : _buildInputBar(containerColor, iconColor);
  }

  Widget _buildInputBar(Color containerColor, Color iconColor) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color menuBg = isDark ? Colors.grey.shade900 : Colors.grey.shade200;

    final TextStyle inputStyle = isIOS
        ? TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: iconColor,
      height: 1.7,
      fontFamily: '.SF UI Text',
      fontFamilyFallback: ['NotoColorEmoji'],
    )
        : GoogleFonts.notoSansArabic(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: iconColor,
      height: 1.7,
    ).copyWith(fontFamilyFallback: ['NotoColorEmoji']);

    return SizedBox(
      height: 55,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent,
            // color: isDark
            //     ? Colors.black.withOpacity(0.1)
            //     : Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  FocusedMenuHolder(

                    menuOffset: 3,
                    openWithTap: true,
                    onPressed: () {

                    },
                    menuWidth: MediaQuery.of(context).size.width * 0.5,
                    blurSize: 4.0,
                    menuBoxDecoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(milliseconds: 200),
                    animateMenuItems: true,
                    menuItems: [
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: const Text("Capture Image"),
                        trailingIcon: Icon(CupertinoIcons.camera, color: iconColor),
                        onPressed: () => widget.onMediaPick(ImageSource.camera, false),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: const Text("Pick Image from Gallery"),
                        trailingIcon: Icon(CupertinoIcons.photo, color: iconColor),
                        onPressed: () => widget.onMediaPick(ImageSource.gallery, false),
                      ),
                      FocusedMenuItem(
                        backgroundColor: menuBg,
                        title: const Text("Pick Video from Gallery"),
                        trailingIcon: Icon(CupertinoIcons.videocam, color: iconColor),
                        onPressed: () => widget.onMediaPick(ImageSource.gallery, true),
                      ),
                    ],
                    leftSide: 0,
                    rightSide: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(CupertinoIcons.paperclip, color: iconColor),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: containerColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Directionality(
                        textDirection: getTextDirection(_controller.text),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: inputStyle,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  _showSend
                      ? CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: IconButton(
                                            icon: Icon(EvaIcons.paperPlaneOutline, color: Colors.purpleAccent),
                                            onPressed: _handleSend,
                                          ),
                      )
                      : CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],

                    child: IconButton(
                                            icon: Icon(CupertinoIcons.mic, color: iconColor),
                                            onPressed: () async {
                        await widget.audioController.startRecording();
                        _startTimer();
                        setState(() => _isRecording = true);
                                            },
                                          ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingUI(Color containerColor, Color iconColor) {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: containerColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 10),
          Text(_formatDuration(_recordDuration), style: TextStyle(color: iconColor)),
          const SizedBox(width: 10),
          Expanded(
            child: AudioWaveforms(
              size: Size(double.infinity, 50),
              recorderController: widget.audioController.recorderController,
              waveStyle: WaveStyle(
                waveColor: Colors.purple.shade400,
                extendWaveform: true,
                showMiddleLine: false,
              ),
              enableGesture: false,
            ),
          ),
          const SizedBox(width: 10),
          _isRecording
              ? IconButton(
            icon: Icon(CupertinoIcons.pause_circle, color: iconColor),
            onPressed: () async {
              await widget.audioController.recorderController.pause();
              _stopTimer();
              setState(() {
                _isRecording = false;
                _isPaused = true;
                _isPreview = true;
              });
            },
          )
              : Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  _stopTimer();
                  widget.audioController.recorderController.reset();
                  setState(() {
                    _isRecording = false;
                    _isPreview = false;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.blue[700]),
                onPressed: () async {
                  setState(() {
                    _isRecording = false;
                    _isPreview = false;
                  });
                  _stopTimer();
                  await widget.audioController.stopRecordingAndUpload(
                    senderId: '',
                    receiverId: '',
                    onSend: (url) => widget.onSendAudio(url),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextDirection getTextDirection(String text) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
