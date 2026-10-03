import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_provider.dart';
import '../widgets/custom_loading_indicator.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final allWorkersAsync = ref.watch(allWorkersProvider);
    final pendingWorkersAsync = ref.watch(workersByStatusProvider('pending'));
    final activeJobsTodayAsync = ref.watch(activeJobsTodayProvider);
    final totalAdminEarningsAsync = ref.watch(totalAdminEarningsProvider);
    final totalPlatformVolumeAsync = ref.watch(totalPlatformVolumeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allUsersProvider);
          ref.invalidate(allWorkersProvider);
          ref.invalidate(workersByStatusProvider('pending'));
          ref.invalidate(allJobsProvider);
          ref.invalidate(jobsByStatusProvider('pending'));
          ref.invalidate(activeJobsTodayProvider);
          ref.invalidate(totalAdminEarningsProvider);
          ref.invalidate(totalPlatformVolumeProvider);
          ref.invalidate(currentMonthJobsCountProvider);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16, vertical: 16),
              children: [
                // Header
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
                    const SizedBox(height: 4),
                    Text(
                      'Real-time metrics & financial overview',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 1. Total Revenue / Commission Main Gradient Banner Card
                Consumer(
                  builder: (context, ref, child) {
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
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
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
                                    'Total Revenue & Commission',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '20% Commission Rate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickStat(
                                totalAdminEarningsAsync.when(
                                  data: (earnings) =>
                                      'Rs. ${earnings.toStringAsFixed(0)}',
                                  loading: () => '...',
                                  error: (_, _) => 'N/A',
                                ),
                                'Total Commission (20%)',
                              ),
                              _buildQuickStat(
                                totalPlatformVolumeAsync.when(
                                  data: (volume) =>
                                      'Rs. ${volume.toStringAsFixed(0)}',
                                  loading: () => '...',
                                  error: (_, _) => 'N/A',
                                ),
                                'Total Revenue Volume',
                              ),
                              _buildQuickStat(
                                monthJobsAsync.when(
                                  data: (count) => count.toString(),
                                  loading: () => '...',
                                  error: (_, _) => 'N/A',
                                ),
                                'Jobs Completed',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // 2. Metrics Section Title
                Text(
                  'Key Performance Indicators',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                isWide
                    ? GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 2.8,
                        children: _buildStatCards(
                          context,
                          ref,
                          allUsersAsync,
                          allWorkersAsync,
                          pendingWorkersAsync,
                          activeJobsTodayAsync,
                          totalAdminEarningsAsync,
                          totalPlatformVolumeAsync,
                        ),
                      )
                    : Column(
                        children: _buildStatCards(
                          context,
                          ref,
                          allUsersAsync,
                          allWorkersAsync,
                          pendingWorkersAsync,
                          activeJobsTodayAsync,
                          totalAdminEarningsAsync,
                          totalPlatformVolumeAsync,
                        ).map((e) => Padding(padding: const EdgeInsets.only(bottom: 14), child: e)).toList(),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildStatCards(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> allUsersAsync,
    AsyncValue<List<dynamic>> allWorkersAsync,
    AsyncValue<List<dynamic>> pendingWorkersAsync,
    AsyncValue<int> activeJobsTodayAsync,
    AsyncValue<double> totalAdminEarningsAsync,
    AsyncValue<double> totalPlatformVolumeAsync,
  ) {
    return [
      _buildStatCard(
        context: context,
        title: 'Total Users',
        subtitle: 'Registered customer accounts',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF2196F3),
        valueAsync: allUsersAsync.whenData(
          (users) => users.length.toString(),
        ),
        onTap: () {
          ref.read(adminBottomNavIndexProvider.notifier).state = 1;
        },
      ),
      _buildStatCard(
        context: context,
        title: 'Total Workers',
        subtitle: 'Registered service providers',
        icon: Icons.engineering_rounded,
        color: const Color(0xFF9C27B0),
        valueAsync: allWorkersAsync.whenData(
          (workers) => workers.length.toString(),
        ),
        onTap: () {
          ref.read(adminBottomNavIndexProvider.notifier).state = 2;
        },
      ),
      _buildStatCard(
        context: context,
        title: 'Pending Approvals',
        subtitle: 'Workers awaiting verification',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFFF9800),
        valueAsync: pendingWorkersAsync.whenData(
          (workers) => workers.length.toString(),
        ),
        badgeText: pendingWorkersAsync.when(
          data: (workers) => workers.isNotEmpty
              ? '${workers.length} Pending'
              : null,
          loading: () => null,
          error: (_, _) => null,
        ),
        onTap: () {
          ref.read(adminBottomNavIndexProvider.notifier).state = 2;
        },
      ),
      _buildStatCard(
        context: context,
        title: 'Active Jobs Today',
        subtitle: 'Jobs requested or active today',
        icon: Icons.play_circle_filled_rounded,
        color: const Color(0xFF4CAF50),
        valueAsync: activeJobsTodayAsync.whenData(
          (count) => count.toString(),
        ),
        onTap: () {
          ref.read(adminBottomNavIndexProvider.notifier).state = 3;
        },
      ),
      _buildStatCard(
        context: context,
        title: 'Total Revenue / Commission',
        subtitle: '20% Admin commission from jobs',
        icon: Icons.monetization_on_rounded,
        color: const Color(0xFF009688),
        valueAsync: totalAdminEarningsAsync.whenData(
          (earnings) => 'Rs. ${earnings.toStringAsFixed(0)}',
        ),
        onTap: () {
          _showFinancialBreakdown(
            context,
            ref,
            totalAdminEarningsAsync,
            totalPlatformVolumeAsync,
          );
        },
      ),
    ];
  }

  void _showFinancialBreakdown(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<double> commissionAsync,
    AsyncValue<double> volumeAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Revenue & Commission Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gross Platform Volume',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        volumeAsync.when(
                          data: (v) => Text(
                            'Rs. ${v.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          loading: () => const Text('...'),
                          error: (_, _) => const Text('N/A'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Admin Commission Rate',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          '20%',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net Admin Revenue',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        commissionAsync.when(
                          data: (c) => Text(
                            'Rs. ${c.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          loading: () => const Text('...'),
                          error: (_, _) => const Text('N/A'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required AsyncValue<String> valueAsync,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        valueAsync.when(
                          data: (value) => Text(
                            value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 18,
                            height: 18,
                            child: CustomLoadingIndicator(size: 18),
                          ),
                          error: (error, _) => const Text(
                            '!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
