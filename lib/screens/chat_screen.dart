import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
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

// Chat screen widget
class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverUsername;

  const ChatScreen({
    required this.receiverId,
    required this.receiverName,
    required this.receiverUsername,
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


  DateTime? lastSeen;
  Timer? _timer;

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder(); // ✅ صححنا الإنشاء هنا فقط
  bool _isRecording = false;
  String _audioFilePath = '';
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

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
    await _audioRecorder.openRecorder(); // ✅ افتح الريكوردر بعد التأكد من الصلاحيات
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("Permission to record audio is denied");
    }
  }

  void _startRecording() async {
    if (_isRecording) return;

    try {
      String path = '${(await getTemporaryDirectory()).path}/audio.m4a';

      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4, // ← صيغة m4a
      );
      setState(() {
        _isRecording = true;
        _audioFilePath = path;
      });
    } catch (e) {
      print("Error starting recorder: $e");
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      _sendAudioMessage();
    } catch (e) {
      print("Error stopping recorder: $e");
    }
  }

  void _sendAudioMessage() async {
    if (_audioFilePath.isNotEmpty) {
      String senderId = box.read('user_id') ?? '';
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      Reference ref = _firebaseStorage.ref().child('audio_messages/$fileName');

      SettableMetadata metadata = SettableMetadata(contentType: 'audio/mp4');

      await ref.putFile(File(_audioFilePath), metadata).whenComplete(() async {
        String downloadUrl = await ref.getDownloadURL();

        chatController.sendMessage(
          senderId,
          widget.receiverId,
          downloadUrl,
          'audio',
        );
      });

      _audioFilePath = ''; // Reset file path after sending
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      if (lastSeen != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    userController.setTypingStatus(false);
    _audioRecorder.closeRecorder();
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, 44),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref("status/${widget.receiverId}")
                      .onValue,
                  builder: (context, snapshot) {
                    String status = "";

                    if (snapshot.hasData &&
                        snapshot.data!.snapshot.value != null) {
                      final data = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map);

                      final currentUserShow = box.read('showOnlineStatus') ?? true;
                      if (currentUserShow) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.receiverId)
                              .snapshots(),
                          builder: (context, firestoreSnap) {
                            if (firestoreSnap.hasData &&
                                firestoreSnap.data!.exists &&
                                (firestoreSnap.data!.data()
                                as Map<String, dynamic>)['isTyping'] == true) {
                              status = "Typing...";
                            } else {
                              if (data['isOnline'] == true) {
                                status = "Online";
                              } else if (data['lastSeen'] != null) {
                                DateTime seen = DateTime.fromMillisecondsSinceEpoch(
                                    data['lastSeen']);
                                Duration diff = DateTime.now().difference(seen);

                                if (diff.inMinutes < 1) {
                                  status = "Last seen just now";
                                } else if (diff.inMinutes < 60) {
                                  status = "Last seen ${diff.inMinutes}m ago";
                                } else if (diff.inHours < 24) {
                                  status = "Last seen ${diff.inHours}h ago";
                                } else {
                                  status =
                                  "Last seen on ${seen.day}/${seen.month} at ${seen.hour.toString().padLeft(2, '0')}:${seen.minute.toString().padLeft(2, '0')}";
                                }
                              }
                            }

                            return _buildUserTitle(status);
                          },
                        );
                      } else {
                        return _buildUserTitle("");
                      }
                    }

                    return _buildUserTitle("");
                  },
                ),
                actions: [
                  IconButton(icon: Icon(Icons.call), onPressed: () {}),
                  IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
                ],
                leading: IconButton(
                    icon: Icon(Icons.arrow_back), onPressed: () => Get.back()),
              ),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: chatController.getMessages(senderId, widget.receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No messages"));
                    }

                    List<MessageModel> messages = snapshot.data!;
                    return SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        children: List.generate(messages.length, (index) {
                          final message = messages[index];
                          final previousMessage =
                          index < messages.length - 1
                              ? messages[index + 1]
                              : null;
                          final nextMessage =
                          index > 0 ? messages[index - 1] : null;

                          return MessageCard(
                            message: message,
                            previousMessage: previousMessage,
                            nextMessage: nextMessage,
                            isSender: message.senderId == senderId,

                          );
                        })..add(SizedBox(height: 10)),
                      ),
                    );
                  },
                ),
              ),

              Container(
                height: 50,
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
                                if (_isRecording) {
                                  _stopRecording();
                                } else {
                                  _startRecording();
                                }
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                onChanged: (value) {
                                  if (value.trim().isNotEmpty) {
                                    userController.setTypingStatus(true);
                                  } else {
                                    userController.setTypingStatus(false);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Type a message",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTitle(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.receiverName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (status.isNotEmpty)
          Text(status, style: TextStyle(fontSize: 12, color: Colors.green)),
      ],
    );
  }

  void _showMediaPicker(
      BuildContext context, String senderId, String receiverId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Capture Image"),
              onTap: () {
                Navigator.pop(context);
                chatController.pickMedia(
                    senderId, receiverId, ImageSource.camera, false);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Pick Image from Gallery"),
              onTap: () {
                Navigator.pop(context);
                chatController.pickMedia(
                    senderId, receiverId, ImageSource.gallery, false);
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library),
              title: Text("Pick Video from Gallery"),
              onTap: () {
                Navigator.pop(context);
                chatController.pickMedia(
                    senderId, receiverId, ImageSource.gallery, true);
              },
            ),
          ],
        );
      },
    );
  }
}
