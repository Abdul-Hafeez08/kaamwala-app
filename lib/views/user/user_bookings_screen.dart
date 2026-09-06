import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../providers/user_provider.dart';
import '../../controllers/booking_controller.dart';
import 'review_screen.dart';
import '../widgets/job_detail_screen.dart';
import 'job_applicants_screen.dart';
import 'job_tracking_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class UserBookingsScreen extends ConsumerWidget {
  const UserBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsStreamProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Bookings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: bookingsAsync.when(
          data: (bookings) {
            final active = bookings
                .where(
                  (j) =>
                      j.status == 'pending' ||
                      j.status == 'open' ||
                      j.status == 'accepted' ||
                      j.status == 'on_the_way' ||
                      j.status == 'working',
                )
                .toList();

            final completed = bookings
                .where(
                  (j) =>
                      j.status == 'completed' ||
                      j.status == 'reviewed',
                )
                .toList();

            final cancelled = bookings
                .where((j) => j.status == 'cancelled')
                .toList();

            return TabBarView(
              children: [
                _BookingList(bookings: active, type: 'active'),
                _BookingList(bookings: completed, type: 'completed'),
                _BookingList(bookings: cancelled, type: 'cancelled'),
              ],
            );
          },
          loading: () => const Center(child: CustomLoadingIndicator()),
          error: (err, _) => Center(
            child: SelectableText(
              'Error: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<JobModel> bookings;
  final String type;

  const _BookingList({required this.bookings, required this.type});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      String message = 'No bookings found';
      IconData icon = Icons.calendar_today;
      if (type == 'completed') {
        message = 'No completed bookings';
        icon = Icons.history;
      } else if (type == 'cancelled') {
        message = 'No cancelled bookings';
        icon = Icons.cancel_rounded;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(booking: bookings[index], type: type);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final JobModel booking;
  final String type;

  const _BookingCard({required this.booking, required this.type});

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return Colors.blue;
      case 'on_the_way':
        return Colors.orange;
      case 'working':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'reviewed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'on_the_way':
        return 'On the way';
      case 'working':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'reviewed':
        return 'Reviewed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (!booking.isGeneralRequest && (booking.status == 'accepted' || booking.status == 'on_the_way' || booking.status == 'working')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobTrackingScreen(job: booking),
            ),
          );
        } else if (booking.isGeneralRequest && booking.status == 'open') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobApplicantsScreen(job: booking),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(job: booking, isAdmin: false),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(32),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.4) 
                  : color.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: booking.workerImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(booking.workerImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    ),
                    child: booking.workerImage.isEmpty
                        ? const Icon(
                            Icons.rocket_launch_rounded,
                            size: 25,
                            color: Color(0xFFFF9800),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.isGeneralRequest && booking.workerName.isEmpty
                              ? 'Marketplace Post'
                              : booking.workerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          booking.serviceType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFFF9800),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(booking.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: _BookingInfoItem(
                      icon: Icons.calendar_today_rounded,
                      text: DateFormat(
                        'MMM dd, yyyy',
                      ).format(booking.scheduledDate),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _BookingInfoItem(
                      icon: Icons.access_time_rounded,
                      text: booking.scheduledTime.isEmpty
                          ? 'N/A'
                          : booking.scheduledTime,
                    ),
                  ),
                ],
              ),
              _BookingInfoItem(
                icon: Icons.location_on_rounded,
                text: booking.address.isEmpty ? 'N/A' : booking.address,
              ),
              if (booking.isGeneralRequest) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: booking.status == 'open'
                        ? const Color(0xFF009688).withValues(alpha: 0.08)
                        : Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        booking.status == 'open'
                            ? Icons.remove_red_eye_rounded
                            : Icons.check_circle_rounded,
                        size: 16,
                        color: booking.status == 'open'
                            ? const Color(0xFF009688)
                            : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.status == 'open'
                              ? (booking.viewedByWorkerIds.isNotEmpty
                                  ? 'Viewed by ${booking.viewedByWorkerIds.length} ${booking.serviceType.toLowerCase()} experts'
                                  : 'Broadcasted to all nearby ${booking.serviceType.toLowerCase()}s')
                              : 'Accepted by ${booking.workerName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: booking.status == 'open'
                                ? const Color(0xFF009688)
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (booking.price > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Rs. ${booking.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
              if (type == 'active' && booking.status == 'pending') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ),
              ],
              if (type == 'marketplace' && booking.status == 'open') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Remove Post'),
                  ),
                ),
              ],
              if (type == 'completed' && booking.status == 'completed') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(booking: booking),
                      ),
                    ),
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Leave a Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
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
      ),
    );
  }

  void _cancelBooking(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(type == 'marketplace' ? 'Remove Post?' : 'Cancel Booking?'),
        content: Text(
          type == 'marketplace'
              ? 'Are you sure you want to remove this marketplace post?'
              : 'Are you sure you want to cancel this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await BookingController().cancelBooking(booking.jobId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _BookingInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BookingInfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
