import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/custom_loading_indicator.dart';

class JobApplicantsScreen extends ConsumerStatefulWidget {
  final JobModel job;

  const JobApplicantsScreen({super.key, required this.job});

  @override
  ConsumerState<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends ConsumerState<JobApplicantsScreen> {
  bool _isLoading = false;

  Future<void> _hireWorker(WorkerModel worker) async {
    setState(() => _isLoading = true);
    try {
      await FirestoreService().updateJob(widget.job.jobId, {
        'status': 'accepted',
        'workerId': worker.workerId,
        'workerName': worker.name,
        'workerImage': worker.profileImage,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You hired ${worker.name}!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: widget.job.applicants.isEmpty
          ? const Center(
              child: Text(
                'No workers have applied yet.\nPlease check back later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : FutureBuilder<List<WorkerModel>>(
              future: _fetchApplicants(widget.job.applicants),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading applicants: ${snapshot.error}'));
                }

                final workers = snapshot.data ?? [];
                if (workers.isEmpty) {
                  return const Center(child: Text('Applicants no longer available.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: workers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: worker.profileImage.isNotEmpty
                                    ? NetworkImage(worker.profileImage)
                                    : null,
                                backgroundColor: const Color(0xFFFF9800),
                                child: worker.profileImage.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          worker.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rs. ${worker.hourlyRate.toStringAsFixed(0)}/${worker.pricingType == 'hourly' ? 'hr' : 'job'}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (worker.experience.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Experience: ${worker.experience}',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _hireWorker(worker),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Hire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<List<WorkerModel>> _fetchApplicants(List<String> applicantIds) async {
    final List<WorkerModel> workers = [];
    final firestore = FirestoreService();
    for (String id in applicantIds) {
      final worker = await firestore.getWorkerDocument(id);
      if (worker != null) {
        workers.add(worker);
      }
    }
    return workers;
  }
}
