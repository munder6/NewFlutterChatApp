import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/chat_controller.dart';
import '../widgets/message_card.dart';
import '../models/message_model.dart';
import '../controller/user_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverUsername;
  final String receiverImage; // ✅ أضف هذا


  const ChatScreen({
    required this.receiverId,
    required this.receiverName,
    required this.receiverUsername,
    required this.receiverImage,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController chatController = Get.put(ChatController());
  final UserController userController = Get.find<UserController>();
  final TextEditingController messageController = TextEditingController();
  final box = GetStorage();
  final FocusNode _focusNode = FocusNode();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _audioFilePath = '';
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    String? senderId = box.read('user_id');
    if (senderId != null) {
      chatController.markMessagesAsRead(senderId, widget.receiverId);
    }
    _startTimer();
  }

  Future<void> _initRecorder() async {
    await _requestPermissions();
    await _audioRecorder.openRecorder();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("Permission denied");
    }
  }

  void _startRecording() async {
    if (_isRecording) return;
    try {
      String path = '${(await getTemporaryDirectory()).path}/audio.m4a';
      await _audioRecorder.startRecorder(toFile: path, codec: Codec.aacMP4);
      _isRecording = true;
      _audioFilePath = path;
    } catch (e) {
      print("Recording error: $e");
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    try {
      await _audioRecorder.stopRecorder();
      _isRecording = false;
      _sendAudioMessage();
    } catch (e) {
      print("Stop error: $e");
    }
  }

  void _sendAudioMessage() async {
    if (_audioFilePath.isEmpty) return;
    String senderId = box.read('user_id') ?? '';
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    Reference ref = _firebaseStorage.ref().child('audio_messages/$fileName');
    await ref.putFile(File(_audioFilePath), SettableMetadata(contentType: 'audio/mp4'));
    String downloadUrl = await ref.getDownloadURL();
    chatController.sendMessage(senderId, widget.receiverId, downloadUrl, 'audio');
    _audioFilePath = '';
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 60), (_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    userController.setTypingStatus(false);
    _audioRecorder.closeRecorder();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? senderId = box.read('user_id');
    if (senderId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Error")),
        body: Center(child: Text("User not found")),
      );
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      )
          : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: _buildAppBar(isDarkMode),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatController.getMessages(senderId, widget.receiverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No messages"));
                  }
                  List<MessageModel> messages = snapshot.data!;
                  return SingleChildScrollView(
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: List.generate(messages.length, (index) {
                        final msg = messages[index];
                        final prev = index < messages.length - 1 ? messages[index + 1] : null;
                        final next = index > 0 ? messages[index - 1] : null;
                        return MessageCard(
                          message: msg,
                          previousMessage: prev,
                          nextMessage: next,
                          isSender: msg.senderId == senderId,
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
            _buildInputBar(isDarkMode, senderId),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return PreferredSize(
      preferredSize: Size.fromHeight(44),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: AppBar(
            backgroundColor: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.3),
            elevation: 0,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Get.back()),
            title: Row(
              children: [
                // صورة المستخدم
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: widget.receiverImage,
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        CircleAvatar(backgroundColor: Colors.grey.shade300),
                    errorWidget: (context, url, error) =>
                        CircleAvatar(backgroundColor: Colors.grey.shade300),
                  ),
                ),
                SizedBox(width: 10),

                // الاسم والحالة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.receiverName,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),

                      // حالة المستخدم (Typing, Online, Last seen)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.receiverId)
                            .snapshots(),
                        builder: (context, firestoreSnap) {
                          String status = "";

                          if (firestoreSnap.hasData &&
                              firestoreSnap.data!.exists) {
                            final firestoreData = firestoreSnap.data!.data()
                            as Map<String, dynamic>;

                            final isTyping = firestoreData['isTyping'] ?? false;

                            if (isTyping) {
                              status = "Typing...";
                            }

                            return StreamBuilder(
                              stream: FirebaseDatabase.instance
                                  .ref("status/${widget.receiverId}")
                                  .onValue,
                              builder: (context, realtimeSnap) {
                                if (realtimeSnap.hasData &&
                                    realtimeSnap.data!.snapshot.value != null) {
                                  final realtimeData =
                                  Map<String, dynamic>.from(
                                      realtimeSnap.data!.snapshot.value
                                      as Map);

                                  final isOnline =
                                      realtimeData['isOnline'] == true;
                                  final lastSeen = realtimeData['lastSeen'];

                                  if (!isTyping) {
                                    if (isOnline) {
                                      status = "Online";
                                    } else if (lastSeen != null) {
                                      final seen = DateTime
                                          .fromMillisecondsSinceEpoch(lastSeen);
                                      final diff =
                                      DateTime.now().difference(seen);

                                      if (diff.inMinutes < 1) {
                                        status = "Last seen just now";
                                      } else if (diff.inMinutes < 60) {
                                        status =
                                        "Last seen ${diff.inMinutes}m ago";
                                      } else if (diff.inHours < 24) {
                                        status =
                                        "Last seen ${diff.inHours}h ago";
                                      } else {
                                        status =
                                        "Last seen on ${seen.day}/${seen.month}";
                                      }
                                    }
                                  }
                                }

                                return Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status == "Online" ||
                                        status == "Typing..."
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                );
                              },
                            );
                          }

                          return SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: Icon(Icons.call), onPressed: () {}),
              IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }


  //
  // Widget _buildUserTitle(String status) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(widget.receiverName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //       if (status.isNotEmpty) Text(status, style: TextStyle(fontSize: 12, color: Colors.green)),
  //     ],
  //   );
  // }

  Widget _buildInputBar(bool isDarkMode, String senderId) {
    return Container(
      height: 55,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: () {
                      _showMediaPicker(context, senderId, widget.receiverId);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: () {
                      _isRecording ? _stopRecording() : _startRecording();
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: TextField(
                        focusNode: _focusNode,
                        controller: messageController,
                        onChanged: (val) {
                          userController.setTypingStatus(val.trim().isNotEmpty);
                        },
                        decoration: InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () {
                      if (messageController.text.isNotEmpty) {
                        chatController.sendMessage(
                          senderId,
                          widget.receiverId,
                          messageController.text,
                          "text",
                        );
                        messageController.clear();
                        userController.setTypingStatus(false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMediaPicker(BuildContext context, String senderId, String receiverId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Capture Image"),
            onTap: () {
              Navigator.pop(context);
              chatController.pickMedia(senderId, receiverId, ImageSource.camera, false);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text("Pick Image from Gallery"),
            onTap: () {
              Navigator.pop(context);
              chatController.pickMedia(senderId, receiverId, ImageSource.gallery, false);
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library),
            title: Text("Pick Video from Gallery"),
            onTap: () {
              Navigator.pop(context);
              chatController.pickMedia(senderId, receiverId, ImageSource.gallery, true);
            },
          ),
        ],
      ),
    );
  }
}
