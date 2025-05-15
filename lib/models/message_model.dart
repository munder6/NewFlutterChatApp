import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  String content;
  final String contentType;
  final bool isRead;
  final DateTime timestamp;
  final String receiverName;
  final String receiverUsername;
  final String? replyToStoryUrl;
  final String? replyToStoryType;
  final String? replyToStoryId;
  String? localPath;

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
    this.localPath,
  });

  /// ✅ factory مع fallback آمن للـ timestamp و id
  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawTimestamp = map['timestamp'];
    final DateTime safeTimestamp;

    if (rawTimestamp is Timestamp) {
      safeTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      safeTimestamp = rawTimestamp;
    } else {
      safeTimestamp = DateTime.now();
    }

    return MessageModel(
      id: map['id'] ?? docId ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      contentType: map['contentType'] ?? 'text',
      isRead: map['isRead'] ?? false,
      timestamp: safeTimestamp,
      receiverName: map['receiverName'] ?? '',
      receiverUsername: map['receiverUsername'] ?? '',
      replyToStoryUrl: map['replyToStoryUrl'],
      replyToStoryType: map['replyToStoryType'],
      replyToStoryId: map['replyToStoryId'],
      localPath: map['localPath'],
    );
  }

  /// ✅ toMap آمن للتخزين مع خيار استخدام توقيت السيرفر
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'contentType': contentType,
      'isRead': isRead,
      'timestamp': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(timestamp),
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      'replyToStoryUrl': replyToStoryUrl,
      'replyToStoryType': replyToStoryType,
      'replyToStoryId': replyToStoryId,
      'localPath': localPath,
    };
  }
}
