import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String profileImage;
  final String address;
  final String location;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage = '',
    this.address = '',
    this.location = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'address': address,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      profileImage: map['profileImage'] ?? '',
      address: map['address'] ?? '',
      location: map['location'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? profileImage,
    String? address,
    String? location,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WorkerModel {
  final String workerId;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String serviceType;
  final String experience;
  final String skills;
  final String location;
  final double latitude;
  final double longitude;
  final bool availability; // 'Open to Work' toggle
  final bool isOnline; // Online status in real-time
  final DateTime? lastSeen; // Last activity timestamp
  final double rating;
  final String approvalStatus;
  final String nic;
  final String nicImageUrl;
  final String pricingType; // 'hourly' or 'fixed'
  final double hourlyRate;
  final DateTime createdAt;

  WorkerModel({
    required this.workerId,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage = '',
    this.serviceType = '',
    this.experience = '',
    this.skills = '',
    this.location = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.availability = true,
    this.isOnline = true,
    this.lastSeen,
    this.rating = 0.0,
    this.approvalStatus = 'pending',
    this.nic = '',
    this.nicImageUrl = '',
    this.pricingType = 'fixed',
    this.hourlyRate = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isVerified => approvalStatus == 'approved';

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'serviceType': serviceType,
      'experience': experience,
      'skills': skills,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'availability': availability,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'rating': rating,
      'approvalStatus': approvalStatus,
      'nic': nic,
      'nicImageUrl': nicImageUrl,
      'pricingType': pricingType,
      'hourlyRate': hourlyRate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      workerId: map['workerId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      serviceType: map['serviceType'] ?? '',
      experience: map['experience'] ?? '',
      skills: map['skills'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      availability: map['availability'] ?? true,
      isOnline: map['isOnline'] ?? true, // Default to TRUE for existing workers
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      approvalStatus: map['approvalStatus'] ?? 'pending',
      nic: map['nic'] ?? '',
      nicImageUrl: map['nicImageUrl'] ?? '',
      pricingType: map['pricingType'] ?? 'fixed',
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  WorkerModel copyWith({
    String? workerId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? serviceType,
    String? experience,
    String? skills,
    String? location,
    double? latitude,
    double? longitude,
    bool? availability,
    bool? isOnline,
    DateTime? lastSeen,
    double? rating,
    String? approvalStatus,
    String? nic,
    String? nicImageUrl,
    String? pricingType,
    double? hourlyRate,
    DateTime? createdAt,
  }) {
    return WorkerModel(
      workerId: workerId ?? this.workerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      serviceType: serviceType ?? this.serviceType,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availability: availability ?? this.availability,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      rating: rating ?? this.rating,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      nic: nic ?? this.nic,
      nicImageUrl: nicImageUrl ?? this.nicImageUrl,
      pricingType: pricingType ?? this.pricingType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
