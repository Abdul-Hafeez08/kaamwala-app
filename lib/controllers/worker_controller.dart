import 'dart:io';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../services/location_service.dart';

class WorkerController {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final LocationService _locationService = LocationService();

  Future<WorkerModel?> getWorkerProfile(String workerId) async {
    return await _firestoreService.getWorkerDocument(workerId);
  }

  Stream<WorkerModel?> streamWorkerProfile(String workerId) {
    return _firestoreService.streamWorkerDocument(workerId);
  }

  Future<void> submitWorkerProfile({
    required String workerId,
    required String name,
    required String email,
    required String phone,
    required String profileImage,
    required String serviceType,
    required String experience,
    required String skills,
    required String location,
    required bool availability,
    required String nic,
    required String nicImageUrl,
    double latitude = 0.0,
    double longitude = 0.0,
    String pricingType = 'fixed',
    double hourlyRate = 0.0,
  }) async {
    // If lat/lng not provided, try to geocode the text address
    double finalLat = latitude;
    double finalLng = longitude;
    if ((finalLat == 0.0 || finalLng == 0.0) && location.trim().isNotEmpty) {
      try {
        final coords = await _locationService.geocodeAddress(location.trim());
        if (coords != null) {
          finalLat = coords['latitude'] ?? 0.0;
          finalLng = coords['longitude'] ?? 0.0;
        }
      } catch (_) {
        // Geocoding failed — continue with zero coords
      }
    }

    final Map<String, dynamic> workerData = {
      'workerId': workerId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'serviceType': serviceType,
      'experience': experience,
      'skills': skills,
      'location': location,
      'latitude': finalLat,
      'longitude': finalLng,
      'availability': availability,
      'isOnline': availability,
      'lastSeen': DateTime.now(),
      'nic': nic,
      'nicImageUrl': nicImageUrl,
      'pricingType': pricingType,
      'hourlyRate': hourlyRate,
    };

    await _firestoreService.updateWorkerDocument(workerId, workerData);
  }

  Future<void> updateAvailability(String workerId, bool isAvailable) async {
    await _firestoreService.updateWorkerDocument(workerId, {
      'availability': isAvailable,
      'isOnline': isAvailable,
      'lastSeen': DateTime.now(),
    });
  }

  /// Set worker online status in the backend
  /// Called when worker logs in or enables app
  Future<void> setWorkerOnline(String workerId) async {
    await _firestoreService.updateWorkerDocument(workerId, {
      'isOnline': true,
      'lastSeen': DateTime.now(),
    });
  }

  /// Set worker offline status in the backend
  /// Called when worker logs out or disables app
  Future<void> setWorkerOffline(String workerId) async {
    await _firestoreService.updateWorkerDocument(workerId, {
      'isOnline': false,
      'lastSeen': DateTime.now(),
    });
  }

  /// Update last seen timestamp to maintain online status
  /// Should be called periodically or on user activity
  Future<void> updateWorkerLastSeen(String workerId) async {
    await _firestoreService.updateWorkerDocument(workerId, {
      'lastSeen': DateTime.now(),
    });
  }

  Future<String?> pickAndUploadImage() async {
    final File? imageFile = await _cloudinaryService.pickImageFromGallery();

    if (imageFile == null) {
      return null;
    }

    final String imageUrl = await _cloudinaryService.uploadImage(
      imageFile: imageFile,
    );
    return imageUrl;
  }

  Future<String?> pickAndUploadImageFromCamera() async {
    final File? imageFile = await _cloudinaryService.pickImageFromCamera();

    if (imageFile == null) {
      return null;
    }

    final String imageUrl = await _cloudinaryService.uploadImage(
      imageFile: imageFile,
    );
    return imageUrl;
  }

  Future<void> updateJobStatus(
    String jobId,
    String status, {
    double? price,
  }) async {
    final Map<String, dynamic> data = {'status': status};

    if (status == 'working') {
      data['startedAt'] = DateTime.now();
    } else if (status == 'completed') {
      data['completedAt'] = DateTime.now();
    }

    if (price != null) {
      data['price'] = price;
    }
    await _firestoreService.updateJob(jobId, data);
  }

  Future<void> acceptOpenJob({
    required String jobId,
    required String workerId,
    required String workerName,
    required String workerImage,
  }) async {
    await _firestoreService.updateJob(jobId, {
      'workerId': workerId,
      'workerName': workerName,
      'workerImage': workerImage,
      'status': 'accepted',
      'isGeneralRequest': false,
    });
  }
}
