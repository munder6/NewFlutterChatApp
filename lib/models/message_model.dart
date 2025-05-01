import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  String content;
  final String contentType;
  final bool isRead;
  final Timestamp timestamp;
  final String receiverName;
  final String receiverUsername;

  // ✅ الحقول الجديدة الخاصة بالرد على الستوري
  final String? replyToStoryUrl;
  final String? replyToStoryType;
  final String? replyToStoryId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.contentType,
    required this.isRead,
    required this.timestamp,
    required this.receiverName,
    required this.receiverUsername,
    this.replyToStoryUrl,
    this.replyToStoryType,
    this.replyToStoryId,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      contentType: map['contentType'],
      isRead: map['isRead'],
      timestamp: map['timestamp'],
      receiverName: map['receiverName'],
      receiverUsername: map['receiverUsername'],
      replyToStoryUrl: map['replyToStoryUrl'],
      replyToStoryType: map['replyToStoryType'],
      replyToStoryId: map['replyToStoryId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'contentType': contentType,
      'isRead': isRead,
      'timestamp': timestamp,
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      // ✅ حقل الرد على ستوري
      'replyToStoryUrl': replyToStoryUrl,
      'replyToStoryType': replyToStoryType,
      'replyToStoryId': replyToStoryId,
    };
  }
}
