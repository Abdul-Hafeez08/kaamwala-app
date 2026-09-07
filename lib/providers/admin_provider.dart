import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/service_model.dart';
import 'auth_provider.dart';

final allWorkersProvider = FutureProvider<List<WorkerModel>>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getAllWorkers();
});

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getAllUsers();
});

final servicesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getServices();
});

final workersByStatusProvider = FutureProvider.family<List<WorkerModel>, String>((ref, status) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getWorkersByApprovalStatus(status);
});

final allJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getAllJobs();
});

final jobsByStatusProvider = FutureProvider.family<List<JobModel>, String>((ref, status) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getJobsByStatus(status);
});

final workerEarningsProvider = FutureProvider.family<double, String>((ref, workerId) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final jobs = await firestoreService.getWorkerJobs(workerId);
  return jobs
      .where((j) => (j.status == 'completed' || j.status == 'reviewed') && j.price > 0)
      .fold<double>(0.0, (sum, job) => sum + job.price);
});

final currentMonthIncomeProvider = FutureProvider<double>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final allJobs = await firestoreService.getAllJobs();
  final now = DateTime.now();
  return allJobs
      .where((j) =>
          (j.status == 'completed' || j.status == 'reviewed') &&
          j.price > 0 &&
          j.completedAt != null &&
          j.completedAt!.month == now.month &&
          j.completedAt!.year == now.year)
      .fold<double>(0.0, (sum, job) => sum + job.price);
});

final currentMonthJobsCountProvider = FutureProvider<int>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final allJobs = await firestoreService.getAllJobs();
  final now = DateTime.now();
  return allJobs
      .where((j) =>
          (j.status == 'completed' || j.status == 'reviewed') &&
          j.completedAt != null &&
          j.completedAt!.month == now.month &&
          j.completedAt!.year == now.year)
      .length;
});

final totalAdminEarningsProvider = FutureProvider<double>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final allJobs = await firestoreService.getAllJobs();
  return allJobs
      .where((j) => (j.status == 'completed' || j.status == 'reviewed') && j.price > 0)
      .fold<double>(0.0, (sum, job) => sum + (job.price * 0.20));
});

final totalPlatformVolumeProvider = FutureProvider<double>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final allJobs = await firestoreService.getAllJobs();
  return allJobs
      .where((j) => (j.status == 'completed' || j.status == 'reviewed') && j.price > 0)
      .fold<double>(0.0, (sum, job) => sum + job.price);
});

/// Full job list for a specific worker — used by admin for detailed earnings view
final workerJobsDetailProvider = FutureProvider.family<List<JobModel>, String>((ref, workerId) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final jobs = await firestoreService.getWorkerJobs(workerId);
  return jobs
      .where((j) => (j.status == 'completed' || j.status == 'reviewed') && j.price > 0)
      .toList()
    ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
});

/// Admin bottom navigation tab index
final adminBottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Active jobs count for today
final activeJobsTodayProvider = FutureProvider<int>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final allJobs = await firestoreService.getAllJobs();
  final now = DateTime.now();
  return allJobs.where((j) {
    final isTerminal = j.status == 'completed' ||
        j.status == 'reviewed' ||
        j.status == 'cancelled' ||
        j.status == 'declined';
    if (isTerminal) return false;

    final isCreatedToday = j.createdAt.year == now.year &&
        j.createdAt.month == now.month &&
        j.createdAt.day == now.day;
    final isScheduledToday = j.scheduledDate.year == now.year &&
        j.scheduledDate.month == now.month &&
        j.scheduledDate.day == now.day;
    final isStartedToday = j.startedAt != null &&
        j.startedAt!.year == now.year &&
        j.startedAt!.month == now.month &&
        j.startedAt!.day == now.day;

    return isCreatedToday || isScheduledToday || isStartedToday || j.status == 'started' || j.status == 'on_the_way';
  }).length;
});

