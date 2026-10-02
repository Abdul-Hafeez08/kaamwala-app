import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_model.dart';
import '../../controllers/worker_controller.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;
  final bool isAdmin;

  const JobDetailScreen({super.key, required this.job, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildSectionCard(
              isDark: isDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.serviceType,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${job.jobId.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(job.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _getStatusColor(job.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. User Message / Description (Show First)
            if (job.description.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.sms_rounded,
                    size: 16,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CUSTOMER MESSAGE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  job.description,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 2. Customer Details
            const Text(
              'CUSTOMER DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_rounded,
                    title: 'Name',
                    value: job.userName.isNotEmpty
                        ? job.userName
                        : 'Unknown Customer',
                  ),
                  if (job.userPhone.isNotEmpty) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.phone_iphone_rounded,
                      title: 'Phone',
                      value: job.userPhone,
                    ),
                  ],
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    title: 'Address',
                    value: job.address.isNotEmpty ? job.address : job.location,
                  ),
                  if (job.latitude != 0.0 && job.longitude != 0.0) ...[
                    const Divider(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri mapUri = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${job.latitude},${job.longitude}',
                          );
                          if (await canLaunchUrl(mapUri)) {
                            await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text(
                          'Navigate via Google Maps',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4285F4),
                          side: const BorderSide(color: Color(0xFF4285F4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Worker Details (Show if accepted/working/completed and worker assigned)
            if (job.workerId.isNotEmpty) ...[
              const Text(
                'ASSIGNED WORKER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildSectionCard(
                isDark: isDark,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(
                        0xFFFF9800,
                      ).withValues(alpha: 0.1),
                      backgroundImage: job.workerImage.isNotEmpty
                          ? NetworkImage(job.workerImage)
                          : null,
                      child: job.workerImage.isEmpty
                          ? const Icon(
                              Icons.engineering_rounded,
                              color: Color(0xFFFF9800),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.workerName.isNotEmpty
                                ? job.workerName
                                : 'Unknown Worker',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Provider ID: ${job.workerId.length > 6 ? job.workerId.substring(0, 6) : job.workerId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Schedule & Timeline
            const Text(
              'TIMELINE & SCHEDULE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.event_rounded,
                    title: 'Scheduled For',
                    value:
                        '${DateFormat('MMM dd, yyyy').format(job.scheduledDate)} at ${job.scheduledTime}',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.post_add_rounded,
                    title: 'Requested On',
                    value: DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(job.createdAt),
                  ),
                  if (job.startedAt != null) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.play_circle_fill_rounded,
                      title: 'Started At',
                      value: DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(job.startedAt!),
                      iconColor: Colors.blue,
                    ),
                  ],
                  if (job.completedAt != null) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.check_circle_rounded,
                      title: 'Completed At',
                      value: DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(job.completedAt!),
                      iconColor: Colors.green,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Pricing & Ratings (If applicable)
            if (job.price > 0 ||
                job.status == 'completed' ||
                job.status == 'reviewed') ...[
              const Text(
                'PAYMENT & REVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildSectionCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.payments_rounded,
                      title: 'Total Charged',
                      value: 'Rs. ${job.price.toStringAsFixed(0)}',
                      valueColor: Colors.green,
                      valueSize: 18,
                    ),
                    if (job.status == 'reviewed') ...[
                      const Divider(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rating: ${job.userRating.toStringAsFixed(1)} / 5.0',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (job.userReview.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    job.userReview,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Accept/Reject Buttons for Workers
            if (job.status == 'pending' && !isAdmin) ...[
              const Divider(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        WorkerController().updateJobStatus(
                          job.jobId,
                          'cancelled',
                        );
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Reject Request',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        WorkerController().updateJobStatus(
                          job.jobId,
                          'accepted',
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Accept Job',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildSectionCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'open':
        return Colors.orange;
      case 'accepted':
      case 'working':
        return Colors.blue;
      case 'completed':
      case 'reviewed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final double? valueSize;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? const Color(0xFFFF9800)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize ?? 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
