import '../models/job_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';

class BookingController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<String> createBooking({
    required String userId,
    required String workerId,
    required String serviceType,
    required String description,
    required String address,
    required String location,
    required String userName,
    required String userPhone,
    required String workerName,
    required String workerImage,
    required DateTime scheduledDate,
    required String scheduledTime,
    bool isGeneralRequest = false,
    String urgency = '',
    String budgetRange = '',
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    final job = JobModel(
      jobId: '',
      userId: userId,
      workerId: workerId,
      serviceType: serviceType,
      description: description,
      address: address,
      location: location,
      userName: userName,
      userPhone: userPhone,
      workerName: workerName,
      workerImage: workerImage,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      status: isGeneralRequest ? 'open' : 'pending',
      isGeneralRequest: isGeneralRequest,
      urgency: urgency,
      budgetRange: budgetRange,
      latitude: latitude,
      longitude: longitude,
    );

    return await _firestoreService.createJob(job);
  }

  Future<void> cancelBooking(String jobId) async {
    await _firestoreService.updateJob(jobId, {'status': 'cancelled'});
  }

  Future<void> submitReview({
    required String jobId,
    required String userId,
    required String workerId,
    required String userName,
    required String userImage,
    required double rating,
    required String review,
  }) async {
    final reviewModel = ReviewModel(
      reviewId: '',
      jobId: jobId,
      userId: userId,
      workerId: workerId,
      userName: userName,
      userImage: userImage,
      rating: rating,
      review: review,
    );

    await _firestoreService.createReview(reviewModel);

    await _firestoreService.updateJob(jobId, {
      'status': 'reviewed',
      'userRating': rating,
      'userReview': review,
    });

    await _firestoreService.updateWorkerRating(workerId);
  }

  Stream<List<JobModel>> streamUserBookings(String userId) {
    return _firestoreService.streamUserJobs(userId);
  }
}
