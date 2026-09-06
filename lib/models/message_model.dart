import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderType; // 'user' or 'worker'
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderType': senderType,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      messageId: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderType: map['senderType'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
