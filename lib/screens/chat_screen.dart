import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../controller/chat_controller.dart';
import '../controller/user_controller.dart';
import '../controller/audio_controller.dart';
import '../models/message_model.dart';
import '../screens/users_profils_screens.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/message_list.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverUsername;
  final String receiverImage;
  final String bio;
  final String birthdate;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverUsername,
    required this.receiverImage,
    required this.bio,
    required this.birthdate,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController chatController = Get.put(ChatController());
  final UserController userController = Get.find<UserController>();
  final box = GetStorage();
  late final AudioController audioController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    audioController = AudioController()..initRecorder();
    _timer = Timer.periodic(Duration(seconds: 60), (_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    userController.setTypingStatus(false);
    audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final senderId = box.read('user_id');

    if (senderId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('User not found')),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
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
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(isDark),
        body: Stack(
          children: [
            Positioned.fill(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatController.getMessages(senderId, widget.receiverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox();
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      chatController.markMessagesAsRead(senderId, widget.receiverId);
                    });
                  }

                  if (messages.isEmpty) {
                    return Center(child: Text("No messages"));
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 61),
                    child: MessageList(
                      messages: messages.reversed.toList(),
                      currentUserId: senderId,
                    ),
                  );
                },
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 0, top: 6, left: 8, right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.7),
                    ),
                    child: SafeArea(
                      top: false,
                      child: MessageInputWidget(
                        onSendText: (text) {
                          chatController.sendMessage(senderId, widget.receiverId, text, "text");
                        },
                        onSendAudio: (url) {
                          chatController.sendMessage(senderId, widget.receiverId, url, "audio");
                        },
                        audioController: audioController,
                        onMediaPick: (source, isVideo) {
                          chatController.pickMedia(senderId, widget.receiverId, source, isVideo);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: Size.fromHeight(55),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
          child: Container(
            height: 110,
            padding: const EdgeInsets.only(top: 50, left: 12, right: 12),
            alignment: Alignment.centerLeft,
            color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(CupertinoIcons.back),
                  onPressed: () => Get.back(),
                  color: AppTheme.getTextColor(isDark),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => UserProfileScreen(
                      receiverId: widget.receiverId,
                      receiverName: widget.receiverName,
                      receiverUsername: widget.receiverUsername,
                      receiverImage: widget.receiverImage,
                      bio: widget.bio,
                      birthdate: widget.birthdate,
                    ));
                  },
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.receiverName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(isDark),
                            ),
                          ),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.receiverId)
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData || !snap.data!.exists) return SizedBox();
                              final userData = snap.data!.data() as Map<String, dynamic>;
                              final isTyping = userData['isTyping'] ?? false;

                              return StreamBuilder(
                                stream: FirebaseDatabase.instance
                                    .ref("status/${widget.receiverId}")
                                    .onValue,
                                builder: (context, statusSnap) {
                                  String status = "";
                                  if (statusSnap.hasData && statusSnap.data!.snapshot.value != null) {
                                    final realtimeData =
                                    Map<String, dynamic>.from(statusSnap.data!.snapshot.value as Map);
                                    final isOnline = realtimeData['isOnline'] == true;
                                    final lastSeen = realtimeData['lastSeen'];

                                    if (isTyping) {
                                      status = "Typing...";
                                    } else if (isOnline) {
                                      status = "Online";
                                    } else if (lastSeen != null) {
                                      final seen =
                                      DateTime.fromMillisecondsSinceEpoch(lastSeen);
                                      final diff = DateTime.now().difference(seen);

                                      if (diff.inMinutes < 1) {
                                        status = "Last seen just now";
                                      } else if (diff.inMinutes < 60) {
                                        status = "Last seen ${diff.inMinutes}m ago";
                                      } else if (diff.inHours < 24) {
                                        status = "Last seen ${diff.inHours}h ago";
                                      } else {
                                        status = "Last seen on ${seen.day}/${seen.month}";
                                      }
                                    }
                                  }

                                  return Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (status == "Online" || status == "Typing...")
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => UserProfileScreen(
                      receiverId: widget.receiverId,
                      receiverName: widget.receiverName,
                      receiverUsername: widget.receiverUsername,
                      receiverImage: widget.receiverImage,
                      bio: widget.bio,
                      birthdate: widget.birthdate,
                    ));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: CachedNetworkImage(
                      imageUrl: widget.receiverImage,
                      height: 40,
                      width: 40,
                      fit: BoxFit.fitHeight,
                      placeholder: (_, __) => CircleAvatar(backgroundColor: Colors.grey.shade300),
                      errorWidget: (_, __, ___) => CircleAvatar(backgroundColor: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
