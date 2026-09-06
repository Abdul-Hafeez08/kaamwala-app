import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'worker_controller.dart';

class AuthController {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String profileImage = '',
  }) async {
    final User? firebaseUser = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );

    if (firebaseUser == null) {
      throw 'Failed to create account. Please try again.';
    }

    final String userId = firebaseUser.uid;

    final UserModel userModel = UserModel(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      role: role,
      profileImage: profileImage,
    );
    await _firestoreService.createUserDocument(userModel);

    if (role == 'worker') {
      final WorkerModel workerModel = WorkerModel(
        workerId: userId,
        name: name,
        email: email,
        phone: phone,
        profileImage: profileImage,
        approvalStatus: 'pending',
      );
      await _firestoreService.createWorkerDocument(workerModel);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final User? firebaseUser = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (firebaseUser == null) {
      throw 'Failed to sign in. Please try again.';
    }

    // Set worker online when they log in
    final userRole = await getCurrentUserRole();
    if (userRole == 'worker') {
      try {
        await WorkerController().setWorkerOnline(firebaseUser.uid);
      } catch (e) {
        // Log but don't fail login if online status update fails
        print('Warning: Could not set worker online status: $e');
      }
    }
  }

  Future<void> signOut() async {
    // Set worker offline when they log out
    final User? currentUser = _authService.currentUser;
    if (currentUser != null) {
      final userRole = await _firestoreService.getUserRole(currentUser.uid);
      if (userRole == 'worker') {
        try {
          await WorkerController().setWorkerOffline(currentUser.uid);
        } catch (e) {
          // Log but don't fail logout if offline status update fails
          print('Warning: Could not set worker offline status: $e');
        }
      }
    }

    await _authService.signOut();
  }

  Future<String?> getCurrentUserRole() async {
    final User? currentUser = _authService.currentUser;
    if (currentUser == null) return null;
    return await _firestoreService.getUserRole(currentUser.uid);
  }

  Future<UserModel?> getCurrentUserData() async {
    final User? currentUser = _authService.currentUser;
    if (currentUser == null) return null;
    return await _firestoreService.getUserDocument(currentUser.uid);
  }
}
