import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_model.dart';
import '../../providers/user_provider.dart';

class JobTrackingScreen extends ConsumerWidget {
  final JobModel job;

  const JobTrackingScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We listen to the specific job to get real-time updates
    final jobsAsync = ref.watch(userBookingsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
      body: jobsAsync.when(
        data: (jobs) {
          // Find the latest version of this job
          final currentJob = jobs.firstWhere(
            (j) => j.jobId == job.jobId,
            orElse: () => job,
          );

          int currentStep = _getStepFromStatus(currentJob.status);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                            : [const Color(0xFFFFD54F), const Color(0xFFFF9800)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
                              backgroundImage: currentJob.workerImage.isNotEmpty
                                  ? NetworkImage(currentJob.workerImage)
                                  : null,
                              child: currentJob.workerImage.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 46, color: Color(0xFFFF9800))
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentJob.workerName.isNotEmpty ? currentJob.workerName : 'Worker',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracking Status',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                  ? Colors.black.withValues(alpha: 0.4) 
                                  : const Color(0xFFFFD54F).withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 4,
                              offset: const Offset(0, 15),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFFFD54F).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTimelineStep(
                              context: context,
                              title: 'Worker Assigned',
                              subtitle: 'Worker has accepted your request.',
                              icon: Icons.assignment_ind_rounded,
                              isCompleted: currentStep >= 1,
                              isLast: false,
                              isDark: isDark,
                            ),
                            _buildTimelineStep(
                              context: context,
                              title: 'On the way',
                              subtitle: 'Worker is heading to your location.',
                              icon: Icons.directions_car_rounded,
                              isCompleted: currentStep >= 2,
                              isLast: false,
                              isDark: isDark,
                            ),
                            _buildTimelineStep(
                              context: context,
                              title: 'Started Working',
                              subtitle: 'Worker has started the job.',
                              icon: Icons.build_rounded,
                              isCompleted: currentStep >= 3,
                              isLast: false,
                              isDark: isDark,
                            ),
                            _buildTimelineStep(
                              context: context,
                              title: 'Completed',
                              subtitle: 'Job has been finished.',
                              icon: Icons.check_circle_rounded,
                              isCompleted: currentStep >= 4,
                              isLast: true,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Navigate to Worker via Google Maps
                      if (currentJob.workerId.isNotEmpty) ...[
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('workers')
                              .doc(currentJob.workerId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox.shrink();
                            }
                            final workerData = snapshot.data!.data() as Map<String, dynamic>;
                            final wLat = (workerData['latitude'] ?? 0.0).toDouble();
                            final wLng = (workerData['longitude'] ?? 0.0).toDouble();
                            if (wLat == 0.0 && wLng == 0.0) return const SizedBox.shrink();

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final Uri mapUri = Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=$wLat,$wLng',
                                  );
                                  if (await canLaunchUrl(mapUri)) {
                                    await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.map_rounded),
                                label: const Text(
                                  'See Worker on Google Maps',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4285F4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }

  int _getStepFromStatus(String status) {
    switch (status) {
      case 'accepted':
        return 1;
      case 'on_the_way':
        return 2;
      case 'working':
        return 3;
      case 'completed':
      case 'reviewed':
        return 4;
      default:
        return 0; // pending, open, cancelled
    }
  }

  Widget _buildTimelineStep({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required bool isLast,
    required bool isDark,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFFFF9800) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]),
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: isCompleted ? const Color(0xFFFF9800) : (isDark ? Colors.white10 : Colors.grey[300]),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompleted 
                          ? (isDark ? Colors.white : Colors.black87) 
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted 
                          ? (isDark ? Colors.white70 : Colors.black54) 
                          : (isDark ? Colors.white24 : Colors.black26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
