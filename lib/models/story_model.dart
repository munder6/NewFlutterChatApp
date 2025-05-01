import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String storyId;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final DateTime expireAt; // ✅ جديد
  final int duration;
  final List<String> viewedBy;

  StoryModel({
    required this.storyId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expireAt, // ✅ جديد
    required this.duration,
    required this.viewedBy,
  });

  factory StoryModel.fromMap(Map<String, dynamic> data, String id) {
    return StoryModel(
      storyId: id,
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expireAt: (data['expireAt'] as Timestamp).toDate(), // ✅ جديد
      duration: data['duration'] ?? 10,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': createdAt,
      'expireAt': expireAt, // ✅ جديد
      'duration': duration,
      'viewedBy': viewedBy,
    };
  }
}
