import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/worker_provider.dart';
import '../../models/job_model.dart';
import '../widgets/job_detail_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class WorkerEarningsScreen extends ConsumerWidget {
  const WorkerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(workerJobsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Earnings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: jobsAsync.when(
        data: (jobs) {
          final completedJobs = jobs
              .where((j) =>
                  (j.status == 'completed' || j.status == 'reviewed') &&
                  j.price > 0)
              .toList()
            ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
          final monthStart = DateTime(now.year, now.month, 1);

          double todayEarnings = 0;
          double weekEarnings = 0;
          double monthEarnings = 0;
          double totalEarnings = 0;

          // Daily earnings for last 7 days (for bar chart)
          final Map<String, double> dailyEarnings = {};
          for (int i = 6; i >= 0; i--) {
            final day = todayStart.subtract(Duration(days: i));
            final key = DateFormat('EEE').format(day);
            dailyEarnings[key] = 0;
          }

          for (var job in completedJobs) {
            totalEarnings += job.price;
            if (!job.scheduledDate.isBefore(todayStart)) {
              todayEarnings += job.price;
            }
            if (!job.scheduledDate.isBefore(weekStart)) {
              weekEarnings += job.price;
            }
            if (!job.scheduledDate.isBefore(monthStart)) {
              monthEarnings += job.price;
            }
            // Fill daily chart data
            final daysDiff = todayStart.difference(DateTime(
              job.scheduledDate.year,
              job.scheduledDate.month,
              job.scheduledDate.day,
            )).inDays;
            if (daysDiff >= 0 && daysDiff < 7) {
              final key = DateFormat('EEE').format(job.scheduledDate);
              dailyEarnings[key] = (dailyEarnings[key] ?? 0) + job.price;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Big Month Earnings Hero ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${monthEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${completedJobs.where((j) => j.scheduledDate.month == now.month && j.scheduledDate.year == now.year).length} jobs completed',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Stats Row ---
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Today', 'Rs. ${todayEarnings.toStringAsFixed(0)}', Icons.today_rounded, const Color(0xFF4CAF50), isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('This Week', 'Rs. ${weekEarnings.toStringAsFixed(0)}', Icons.date_range_rounded, const Color(0xFF2196F3), isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Total Jobs', completedJobs.length.toString(), Icons.check_circle_rounded, const Color(0xFF9C27B0), isDark)),
                  ],
                ),
                const SizedBox(height: 32),

                // --- Bar Chart ---
                Text(
                  'Weekly Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : const Color(0xFFFF9800).withValues(alpha: 0.1),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFFF9800).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: _EarningsBarChart(dailyEarnings: dailyEarnings, isDark: isDark),
                ),
                const SizedBox(height: 32),

                // --- Per-Job Breakdown ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: Rs. ${totalEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (completedJobs.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedJobs.length,
                    itemBuilder: (context, index) {
                      return _buildJobBreakdownCard(context, completedJobs[index], isDark);
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (err, _) => Center(child: SelectableText('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No earnings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your assigned jobs to\nstart seeing money here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobBreakdownCard(BuildContext context, JobModel job, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreen(job: job, isAdmin: false),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.userName.isNotEmpty ? job.userName : 'Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy • hh:mm a').format(job.scheduledDate),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+Rs. ${job.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      'Net: Rs. ${(job.price * 0.8).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white54 : Colors.black54,
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
}

// --- Custom Painted Bar Chart ---
class _EarningsBarChart extends StatelessWidget {
  final Map<String, double> dailyEarnings;
  final bool isDark;

  const _EarningsBarChart({required this.dailyEarnings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxVal = dailyEarnings.values.fold<double>(0, (a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dailyEarnings.entries.map((entry) {
          final ratio = entry.value / effectiveMax;
          final isToday = entry.key == DateFormat('EEE').format(DateTime.now());

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (entry.value > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${(entry.value / 1000).toStringAsFixed(1)}k',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 10 + (ratio * 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isToday
                            ? [const Color(0xFFFF9800), const Color(0xFFFFB74D)]
                            : isDark
                                ? [Colors.white24, Colors.white10]
                                : [Colors.black12, Colors.black.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                      color: isToday
                          ? const Color(0xFFFF9800)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
