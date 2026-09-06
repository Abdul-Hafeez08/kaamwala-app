import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? workerId;
  final String? workerName;
  final String subject;
  final String message;
  final String status; // 'pending', 'resolved'
  final DateTime createdAt;

  ComplaintModel({
    required this.complaintId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.workerId,
    this.workerName,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'workerId': workerId,
      'workerName': workerName,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ComplaintModel(
      complaintId: map['complaintId'] ?? id ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      workerId: map['workerId'],
      workerName: map['workerName'],
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
