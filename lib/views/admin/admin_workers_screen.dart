import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class AdminWorkersScreen extends ConsumerStatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  ConsumerState<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends ConsumerState<AdminWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateWorkerStatus(String workerId, String status) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateWorkerDocument(workerId, {
        'approvalStatus': status,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worker status updated to $status')),
      );

      ref.invalidate(workersByStatusProvider('approved'));
      ref.invalidate(workersByStatusProvider('pending'));
      ref.invalidate(workersByStatusProvider('rejected'));
      ref.invalidate(allWorkersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 8,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF9800),
          indicatorWeight: 4,
          labelColor: const Color(0xFFFF9800),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WorkerList(
            status: 'approved',
            onAction: (workerId) => _updateWorkerStatus(workerId, 'rejected'),
            actionLabel: 'Reject',
            actionColor: Colors.red,
          ),

          _WorkerList(
            status: 'pending',
            onAction: (workerId) => _updateWorkerStatus(workerId, 'approved'),
            actionLabel: 'Approve',
            actionColor: Colors.green,
          ),
          _WorkerList(
            status: 'rejected',
            onAction: (workerId) => _updateWorkerStatus(workerId, 'approved'),
            actionLabel: 'Approve',
            actionColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _WorkerList extends ConsumerWidget {
  final String status;
  final Function(String) onAction;
  final String actionLabel;
  final Color actionColor;

  const _WorkerList({
    required this.status,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersByStatusProvider(status));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void showWorkerDetails(BuildContext context, WorkerModel worker) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            worker.approvalStatus == 'pending'
                ? 'Review Application'
                : 'Worker Profile',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF9800),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: worker.profileImage.isNotEmpty
                          ? NetworkImage(worker.profileImage)
                          : null,
                      child: worker.profileImage.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(label: 'NAME', value: worker.name),
                _DetailRow(label: 'SERVICE TYPE', value: worker.serviceType),
                _DetailRow(label: 'PHONE', value: worker.phone),
                _DetailRow(label: 'EMAIL', value: worker.email),
                _DetailRow(label: 'NIC NUMBER', value: worker.nic),
                _DetailRow(label: 'EXPERIENCE', value: worker.experience),
                _DetailRow(label: 'LOCATION', value: worker.location),
                _DetailRow(label: 'SKILLS', value: worker.skills),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final jobsAsync = ref.watch(
                      workerJobsDetailProvider(worker.workerId),
                    );
                    return jobsAsync.when(
                      data: (completedJobs) {
                        final now = DateTime.now();
                        final todayStart = DateTime(now.year, now.month, now.day);
                        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

                        double todayEarnings = 0;
                        double weekEarnings = 0;
                        double monthEarnings = 0;
                        double totalEarnings = 0;

                        for (var job in completedJobs) {
                          totalEarnings += job.price;
                          if (!job.scheduledDate.isBefore(todayStart)) {
                            todayEarnings += job.price;
                          }
                          if (!job.scheduledDate.isBefore(weekStart)) {
                            weekEarnings += job.price;
                          }
                          if (job.scheduledDate.month == now.month &&
                              job.scheduledDate.year == now.year) {
                            monthEarnings += job.price;
                          }
                        }

                        return Column(
                          children: [
                            // Total Earnings Hero
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'TOTAL EARNINGS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white70,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rs. ${totalEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${completedJobs.length} jobs completed',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Today / Week / Month row
                            Row(
                              children: [
                                _AdminStatChip('Today', 'Rs. ${todayEarnings.toStringAsFixed(0)}', isDark),
                                const SizedBox(width: 8),
                                _AdminStatChip('Week', 'Rs. ${weekEarnings.toStringAsFixed(0)}', isDark),
                                const SizedBox(width: 8),
                                _AdminStatChip('Month', 'Rs. ${monthEarnings.toStringAsFixed(0)}', isDark),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Recent jobs list
                            if (completedJobs.isNotEmpty) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Recent Jobs',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...completedJobs.take(5).map((job) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.userName.isNotEmpty ? job.userName : 'Customer',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              DateFormat('dd MMM yyyy').format(job.scheduledDate),
                                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${job.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(child: CustomLoadingIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    );
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onAction(worker.workerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                overlayColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workersByStatusProvider(status));
      },
      child: workersAsync.when(
        data: (workers) {
          if (workers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.engineering_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $status workers found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.03),
                  ),
                ),
                child: InkWell(
                  onTap: () => showWorkerDetails(context, worker),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: worker.profileImage.isNotEmpty
                                  ? NetworkImage(worker.profileImage)
                                  : null,
                              child: worker.profileImage.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        worker.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final earnings = ref.watch(
                                            workerEarningsProvider(
                                              worker.workerId,
                                            ),
                                          );
                                          return earnings.when(
                                            data: (e) => Text(
                                              'Rs. ${e.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                            loading: () =>
                                                const SizedBox.shrink(),
                                            error: (_, _) =>
                                                const SizedBox.shrink(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF9800,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      worker.serviceType,
                                      style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  showWorkerDetails(context, worker),
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                        _InfoRow(
                          icon: Icons.phone_iphone_rounded,
                          text: worker.phone,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          text: worker.location,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => onAction(worker.workerId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: actionColor.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: actionColor,
                              overlayColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              actionLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (err, stack) => Center(
          child: SelectableText(
            'Error: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF9800)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.isEmpty ? 'Not provided' : text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white24 : Colors.black26,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Divider(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            height: 1,
          ),
        ],
      ),
    );
  }
}

class _AdminStatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _AdminStatChip(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
