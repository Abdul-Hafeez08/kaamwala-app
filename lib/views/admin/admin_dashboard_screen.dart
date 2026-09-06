import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_provider.dart';

import '../widgets/custom_loading_indicator.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWorkersAsync = ref.watch(allWorkersProvider);
    final pendingWorkersAsync = ref.watch(workersByStatusProvider('pending'));
    final allJobsAsync = ref.watch(allJobsProvider);
    final pendingJobsAsync = ref.watch(jobsByStatusProvider('pending'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allWorkersProvider);
          ref.invalidate(workersByStatusProvider('pending'));
          ref.invalidate(allJobsProvider);
          ref.invalidate(jobsByStatusProvider('pending'));
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Real-time metrics for your platform',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 1. Platform Earnings Card (At Top)
                Consumer(
                  builder: (context, ref, child) {
                    final adminEarningsAsync = ref.watch(
                      totalAdminEarningsProvider,
                    );
                    final platformVolumeAsync = ref.watch(
                      totalPlatformVolumeProvider,
                    );
                    final monthJobsAsync = ref.watch(
                      currentMonthJobsCountProvider,
                    );

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E1E1E),
                                  const Color(0xFF121212),
                                ]
                              : [
                                  const Color(0xFF2E7D32),
                                  const Color(0xFF4CAF50),
                                ], // Green for earnings
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.black
                                        : const Color(0xFF2E7D32))
                                    .withValues(alpha: 0.2),
                            blurRadius: 20,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Admin Profit',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'From 20% Service Fee',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildQuickStat(
                                adminEarningsAsync.when(
                                  data: (earnings) =>
                                      'Rs. ${earnings.toStringAsFixed(0)}',
                                  loading: () => '...',
                                  error: (_, _) => 'N/A',
                                ),
                                'Total Earnings',
                              ),
                              const SizedBox(width: 32),
                              _buildQuickStat(
                                platformVolumeAsync.when(
                                  data: (volume) =>
                                      'Rs. ${volume.toStringAsFixed(0)}',
                                  loading: () => '...',
                                  error: (_, _) => 'N/A',
                                ),
                                'Total Volume',
                              ),
                              const SizedBox(width: 32),
                              _buildQuickStat(
                                monthJobsAsync.when(
                                  data: (count) => count.toString(),
                                  loading: () => '...',
                                  error: (_, _) => 'N/A',
                                ),
                                'Jobs Done',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // 2. Platform Stats List
                Column(
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Total Workers',
                      icon: Icons.engineering_rounded,
                      color: Colors.blue,
                      valueAsync: allWorkersAsync.whenData(
                        (workers) => workers.length.toString(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      context: context,
                      title: 'Pending Approvals',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFFF9800),
                      valueAsync: pendingWorkersAsync.whenData(
                        (workers) => workers.length.toString(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      context: context,
                      title: 'Total Jobs',
                      icon: Icons.assignment_rounded,
                      color: Colors.indigo,
                      valueAsync: allJobsAsync.whenData(
                        (jobs) => jobs.length.toString(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      context: context,
                      title: 'Active Jobs',
                      icon: Icons.play_circle_filled_rounded,
                      color: Colors.orange,
                      valueAsync: pendingJobsAsync.whenData(
                        (jobs) => jobs.length.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required AsyncValue<String> valueAsync,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                valueAsync.when(
                  data: (value) => Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomLoadingIndicator(size: 20),
                  ),
                  error: (error, _) => const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ],
      ),
    );
  }
}
