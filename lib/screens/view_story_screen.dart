import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player/video_player.dart';
import '../controller/chat_controller.dart';
import '../controller/story_controller.dart';
import '../models/story_model.dart';
import '../app_theme.dart';
import '../widgets/story_viewers.dart';

class StoryViewScreen extends StatefulWidget {
  final String ownerId;
  final List<StoryModel> stories;
  final bool isOwner;


  StoryViewScreen({required this.ownerId, required this.stories, this.isOwner = false});

  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  Timer? _timer;
  VideoPlayerController? _videoController;
  final StoryController storyController = Get.find();
  final TextEditingController _replyController = TextEditingController();
  late AnimationController _animationController;
  Map<String, dynamic>? userInfo;
  bool isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _startStory();
    _loadUserInfo();
    _startStory();
  }

  void _loadUserInfo() async {
    userInfo = await storyController.getUserInfo(widget.ownerId);
    setState(() {
      isUserLoading = false;
    });
  }

  void _startStory() async {
    final story = widget.stories[currentIndex];
    if (story.mediaType == 'video') {
      _videoController = VideoPlayerController.network(story.mediaUrl);
      await _videoController!.initialize();
      _videoController!.play();
      _videoController!.addListener(() => setState(() {}));
    }

    _animationController.stop();
    _animationController.reset();
    _animationController.duration = Duration(seconds: story.duration);
    _animationController.forward();

    _timer?.cancel();
    _timer = Timer(Duration(seconds: story.duration), _nextStory);

    if (!widget.isOwner) {
      await storyController.markStoryAsViewed(widget.ownerId, story.storyId, GetStorage().read('user_id'));
    }
  }



  void _nextStory() {
    if (currentIndex < widget.stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      _disposeVideo();
      _startStory();
    } else {
      Get.back();
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _disposeVideo();
      _startStory();
    }
  }

  void _pauseStory() {
    _animationController.stop();
    _timer?.cancel();
  }

  void _resumeStory() {
    final remainingDuration = _animationController.duration! * (1 - _animationController.value);
    _animationController.forward();
    _timer = Timer(remainingDuration, _nextStory);
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pauseStory(),
        onTapUp: (details) {
          _resumeStory();

          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onTapCancel: () => _resumeStory(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              Get.back();
            } else if (details.primaryVelocity! < 0) {
              if(widget.isOwner) {
                showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => StoryViewersBottomSheet(
                  viewerIds: widget.stories[currentIndex].viewedBy,
                ),
              );
              }
            }
          }
        },

        child: Stack(
          children: [
            Center(
              child: story.mediaType == 'image'
                  ? CachedNetworkImage(imageUrl: story.mediaUrl, fit: BoxFit.contain)
                  : (_videoController != null && _videoController!.value.isInitialized)
                  ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
                  : CircularProgressIndicator(),
            ),
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شريط التقدم بلونين
                  Row(
                    children: widget.stories.map((s) {
                      final index = widget.stories.indexOf(s);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Stack(
                            children: [
                              // الشريط الباهت الخلفي
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // الشريط المتحرك
                              if (index == currentIndex)
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      widthFactor: _animationController.value,
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              else if (index < currentIndex)
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  if (!isUserLoading && userInfo != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: CachedNetworkImageProvider(
                            userInfo!['profileImage'] ?? 'https://i.pravatar.cc/150?u=default',
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isOwner ? "Your Story" : "@${userInfo!['username']}" ?? '',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatTimeAgo(story.createdAt),
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        )
                      ],
                    ),
                  ]
                ],
              ),
            ),
            if (widget.isOwner)
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: (){
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => StoryViewersBottomSheet(
                                  viewerIds: widget.stories[currentIndex].viewedBy,
                                ),
                              );
                          },
                           icon: Icon(Icons.remove_red_eye, color: Colors.white)
                        ),
                      ],
                    ),
                    // IconButton(
                    //   icon: Icon(Icons.expand_less, color: Colors.white),
                    //
                    // )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openReplySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 150,
          child: Column(
            children: [
              Text('Reply to story', style: TextStyle(color: Colors.white, fontSize: 18)),
              SizedBox(height: 10),
              TextField(
                controller: _replyController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final text = _replyController.text.trim();
                  if (text.isNotEmpty) {
                    final currentStory = widget.stories[currentIndex];
                    final currentUserId = GetStorage().read('user_id');
                    final chatController = Get.find<ChatController>();

                    await chatController.sendMessage(
                      currentUserId,
                      widget.ownerId,
                      text,
                      'text',
                      replyToStoryUrl: currentStory.mediaUrl,
                      replyToStoryType: currentStory.mediaType,
                      replyToStoryId: currentStory.storyId,
                    );

                    _replyController.clear();
                    Get.back();
                    Get.snackbar("تم الإرسال", "تم إرسال ردك على الستوري");
                  }
                },
                child: Text('Send'),
              )
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
