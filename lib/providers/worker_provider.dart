import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import 'auth_provider.dart';

final workerProfileStreamProvider = StreamProvider<WorkerModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.streamWorkerDocument(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

final workerProfileProvider = FutureProvider<WorkerModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final firestoreService = ref.read(firestoreServiceProvider);
      return await firestoreService.getWorkerDocument(user.uid);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final workerApprovalStatusProvider = StreamProvider<String>((ref) {
  final workerStream = ref.watch(workerProfileStreamProvider);

  return workerStream.when(
    data: (worker) => Stream.value(worker?.approvalStatus ?? 'pending'),
    loading: () => Stream.value('pending'),
    error: (_, _) => Stream.value('pending'),
  );
});

final workerJobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.streamWorkerJobs(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final openJobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  final workerAsync = ref.watch(workerProfileStreamProvider);

  return workerAsync.when(
    data: (worker) {
      if (worker == null) return Stream.value([]);
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.streamOpenJobsByCategory(worker.serviceType);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});
