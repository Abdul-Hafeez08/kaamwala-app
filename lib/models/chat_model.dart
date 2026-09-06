import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String userId;
  final String workerId;
  final String userName;
  final String userImage;
  final String workerName;
  final String workerImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCountUser;
  final int unreadCountWorker;

  ChatModel({
    required this.chatId,
    required this.userId,
    required this.workerId,
    required this.userName,
    required this.userImage,
    required this.workerName,
    required this.workerImage,
    required this.lastMessage,
    this.unreadCountUser = 0,
    this.unreadCountWorker = 0,
    DateTime? lastMessageTime,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userId': userId,
      'workerId': workerId,
      'userName': userName,
      'userImage': userImage,
      'workerName': workerName,
      'workerImage': workerImage,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCountUser': unreadCountUser,
      'unreadCountWorker': unreadCountWorker,
      'participants': [userId, workerId], // For easier querying
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      chatId: id,
      userId: map['userId'] ?? '',
      workerId: map['workerId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      workerName: map['workerName'] ?? '',
      workerImage: map['workerImage'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      unreadCountUser: map['unreadCountUser'] ?? 0,
      unreadCountWorker: map['unreadCountWorker'] ?? 0,
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
