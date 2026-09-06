import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String jobId;
  final String userId;
  final String workerId;
  final String userName;
  final String userImage;
  final double rating;
  final String review;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.jobId,
    required this.userId,
    required this.workerId,
    this.userName = '',
    this.userImage = '',
    required this.rating,
    this.review = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'jobId': jobId,
      'userId': userId,
      'workerId': workerId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] ?? '',
      jobId: map['jobId'] ?? '',
      userId: map['userId'] ?? '',
      workerId: map['workerId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      review: map['review'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
