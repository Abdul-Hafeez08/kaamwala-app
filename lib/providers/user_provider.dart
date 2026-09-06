import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final firestoreService = ref.read(firestoreServiceProvider);
      return await firestoreService.getUserDocument(user.uid);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final availableServicesProvider = FutureProvider<List<ServiceCategory>>((
  ref,
) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getServices();
});

final workersByServiceProvider =
    FutureProvider.family<List<WorkerModel>, String>((ref, serviceType) async {
      final firestoreService = ref.read(firestoreServiceProvider);
      return await firestoreService.getApprovedWorkersByService(serviceType);
    });

final allApprovedWorkersProvider = FutureProvider<List<WorkerModel>>((
  ref,
) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final workers = await firestoreService.getAllWorkers();
  return workers
      .where(
        (worker) =>
            worker.serviceType.trim().isNotEmpty ||
            worker.location.trim().isNotEmpty,
      )
      .toList();
});

final userBookingsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.streamUserJobs(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final workerReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  workerId,
) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getWorkerReviews(workerId);
});

/// REAL-TIME stream of all available workers (availability == true).
/// This replaces the stale FutureProvider so customers see live updates
/// when workers go online/offline.
final nearbyAvailableWorkersStreamProvider =
    StreamProvider<List<WorkerModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamAvailableWorkers();
});

