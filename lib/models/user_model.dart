import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String profileImage;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool showOnlineStatus;
  final DateTime createdAt;
  final bool isTyping;

  UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.profileImage,
    required this.isOnline,
    required this.lastSeen,
    required this.showOnlineStatus,
    required this.createdAt,
    required this.isTyping,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'],
      fullName: map['fullName'],
      username: map['username'],
      email: map['email'],
      profileImage: map['profileImage'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isTyping: map['isTyping'] ?? false,
    );
  }
}