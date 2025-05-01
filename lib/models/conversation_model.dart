import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String receiverName;
  final String receiverUsername;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadMessages;
  final String receiverImage;

  ConversationModel(
     {
    required this.id,
    required this.receiverName,
    required this.receiverUsername,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadMessages,
    required this.receiverImage
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverUsername: map['receiverUsername'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      receiverImage: map['receiverImage'] ?? '', // ✅ جديد
      unreadMessages: map.containsKey('unreadMessages') ? map['unreadMessages'] : 0, // ✅ تأمين القيمة
    );
  }
}
