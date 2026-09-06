import 'dart:io';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class UserController {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<UserModel?> getUserProfile(String userId) async {
    return await _firestoreService.getUserDocument(userId);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    await _firestoreService.updateUserDocument(userId, updatedData);
  }

  Future<String?> pickAndUploadImage() async {
    final File? imageFile = await _cloudinaryService.pickImageFromGallery();
    if (imageFile == null) return null;
    final String imageUrl = await _cloudinaryService.uploadImage(imageFile: imageFile);
    return imageUrl;
  }

  Future<List<WorkerModel>> getWorkersByService(String serviceType) async {
    return await _firestoreService.getApprovedWorkersByService(serviceType);
  }
}
