import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/worker_provider.dart';
import 'worker_job_requests_screen.dart';
import 'worker_active_jobs_screen.dart';
import 'worker_completed_jobs_screen.dart';
import 'worker_earnings_screen.dart';
import 'find_jobs_screen.dart';
import '../chat/chat_list_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../../providers/chat_provider.dart';
import '../widgets/curved_bottom_nav.dart';
import '../widgets/worker_drawer.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';
import '../../controllers/worker_controller.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  int _currentTabIndex = 0;

  final List<Widget> _screens = const [
    _DashboardHome(),
    FindJobsScreen(),
    WorkerJobRequestsScreen(),
    WorkerActiveJobsScreen(),
    WorkerEarningsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatScreen()),
          );
        },
        backgroundColor: const Color(0xFFFF9800),
        elevation: 6,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      body: _screens[_currentTabIndex],
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          CurvedNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
          CurvedNavItem(icon: Icons.search_rounded, activeIcon: Icons.manage_search_rounded, label: 'Find Jobs'),
          CurvedNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Requests'),
          CurvedNavItem(icon: Icons.work_outline_rounded, activeIcon: Icons.work_rounded, label: 'Active'),
          CurvedNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Earnings'),
        ],
      ),
    );
  }
}

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerStream = ref.watch(workerProfileStreamProvider);
    final jobsAsync = ref.watch(workerJobsStreamProvider);

    return workerStream.when(
      data: (worker) {
        final jobs = jobsAsync.valueOrNull ?? [];
        final pendingJobsList = jobs.where((j) => j.status == 'pending' && j.workerId == worker?.workerId).toList();
        final openGeneralJobs = jobs.where((j) => j.isGeneralRequest && j.status == 'open' && j.serviceType == worker?.serviceType).toList();
        
        final pendingJobs = pendingJobsList.length;
        final activeJobs = jobs.where((j) => j.status == 'accepted' || j.status == 'on_the_way' || j.status == 'working').length;
        final completedJobs = jobs.where((j) => j.status == 'completed' || j.status == 'reviewed').length;

        final displayName = (worker?.name ?? '').trim().isNotEmpty
            ? worker!.name
            : 'Provider';

        return Scaffold(
          drawer: const WorkerDrawer(),
          appBar: AppBar(
            title: const Text('Kaamwala', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(totalUnreadCountWorkerProvider);
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    offset: const Offset(-2, 2),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatListScreen(isWorker: true),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              worker?.serviceType ?? 'Expert Service',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildAvailabilityToggle(context, worker!),
                    const SizedBox(height: 32),
                    
                    if (pendingJobsList.isNotEmpty) ...[
                      const Text(
                        'Incoming Request',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      _buildIncomingRequests(context, pendingJobsList.first, ref),
                      const SizedBox(height: 32),
                    ],

                    const Text(
                      'Nearby Posted Jobs',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildNearbyJobsFeed(context, openGeneralJobs),
                    const SizedBox(height: 32),

                    const Text(
                      'Job Statistics',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
    
                    Column(
                      children: [
                        _buildStatCard(context, 'Pending Jobs', pendingJobs.toString(), Icons.inbox_rounded, Colors.blue),
                        const SizedBox(height: 12),
                        _buildStatCard(context, 'Active Jobs', activeJobs.toString(), Icons.play_circle_filled_rounded, Colors.orange),
                        const SizedBox(height: 12),
                        _buildStatCard(context, 'Completed Services', completedJobs.toString(), Icons.check_circle_rounded, Colors.green),
                        const SizedBox(height: 12),
                        _buildStatCard(context, 'Worker Rating', worker.rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 32),
    
                    const Text(
                      'Quick Navigation',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
    
                    _QuickLinkTile(
                      icon: Icons.history_rounded,
                      title: 'Job History',
                      subtitle: 'View all your past services',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const WorkerCompletedJobsScreen(),
                        ));
                      },
                    ),
                    _QuickLinkTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Payments',
                      subtitle: 'Check your earnings and history',
                      onTap: () {
                        // Navigate to earnings
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CustomLoadingIndicator())),
      error: (error, _) => Scaffold(body: Center(child: SelectableText('Error: $error'))),
    );
  }

  Widget _buildAvailabilityToggle(BuildContext context, dynamic worker) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAvailable = worker.availability;
    final WorkerController workerController = WorkerController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFFF9800))
                .withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF4CAF50).withValues(alpha: 0.35)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvailable ? 'You are ONLINE' : 'You are OFFLINE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isAvailable ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAvailable ? 'Ready to accept jobs' : 'Turn on to get requests',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: isAvailable,
            activeTrackColor: Colors.green.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
            onChanged: (val) {
              workerController.updateAvailability(worker.workerId, val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequests(BuildContext context, dynamic job, WidgetRef ref) {
    final WorkerController workerController = WorkerController();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D00), Color(0xFFD50000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D00).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Job Request!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _AnimatedCountdownRing(
                onComplete: () {
                  workerController.updateJobStatus(job.id, 'rejected');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.serviceType,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.address,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => workerController.updateJobStatus(job.id, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => workerController.updateJobStatus(job.id, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Accept Job', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyJobsFeed(BuildContext context, List<dynamic> openJobs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (openJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.radar_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No jobs nearby right now.',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: openJobs.map((job) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work_rounded, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceType,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.address,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to job details or apply logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white10 : Colors.black12),
        ],
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFF9800)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _AnimatedCountdownRing extends StatefulWidget {
  final VoidCallback onComplete;
  const _AnimatedCountdownRing({required this.onComplete});

  @override
  State<_AnimatedCountdownRing> createState() => _AnimatedCountdownRingState();
}

class _AnimatedCountdownRingState extends State<_AnimatedCountdownRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..reverse(from: 1.0).whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining = (_controller.value * 60).ceil();
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: _controller.value,
                strokeWidth: 4,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: _controller.value > 0.3 ? Colors.green : Colors.red,
              ),
            ),
            Text(
              '$remaining',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _controller.value > 0.3 ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}
