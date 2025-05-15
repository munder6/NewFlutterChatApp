import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String receiverName;
  final String receiverUsername;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadMessages;
  final String receiverImage;

  ConversationModel({
    required this.id,
    required this.receiverName,
    required this.receiverUsername,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadMessages,
    required this.receiverImage,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final DateTime safeTimestamp;

    if (rawTimestamp is Timestamp) {
      safeTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      safeTimestamp = rawTimestamp;
    } else {
      safeTimestamp = DateTime.now(); // fallback للتأكد من عدم الانهيار
    }

    return ConversationModel(
      id: map['id'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverUsername: map['receiverUsername'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      timestamp: safeTimestamp,
      receiverImage: map['receiverImage'] ?? '',
      unreadMessages: map['unreadMessages'] is int ? map['unreadMessages'] : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      'lastMessage': lastMessage,
      'timestamp': Timestamp.fromDate(timestamp),
      'receiverImage': receiverImage,
      'unreadMessages': unreadMessages,
    };
  }
}
