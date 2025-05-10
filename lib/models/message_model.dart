import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String receiverId;

  @HiveField(3)
  String content;

  @HiveField(4)
  final String contentType;

  @HiveField(5)
  final bool isRead;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String receiverName;

  @HiveField(8)
  final String receiverUsername;

  @HiveField(9)
  final String? replyToStoryUrl;

  @HiveField(10)
  final String? replyToStoryType;

  @HiveField(11)
  final String? replyToStoryId;

  @HiveField(12)
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

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      contentType: map['contentType'],
      isRead: map['isRead'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      receiverName: map['receiverName'],
      receiverUsername: map['receiverUsername'],
      replyToStoryUrl: map['replyToStoryUrl'],
      replyToStoryType: map['replyToStoryType'],
      replyToStoryId: map['replyToStoryId'],
        localPath: map['localPath'],
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
      'timestamp': Timestamp.fromDate(timestamp),
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      'replyToStoryUrl': replyToStoryUrl,
      'replyToStoryType': replyToStoryType,
      'replyToStoryId': replyToStoryId,
      'localPath': localPath,
    };
  }
}
