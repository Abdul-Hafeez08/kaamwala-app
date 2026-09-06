import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../providers/user_provider.dart';
import 'booking_screen.dart';
import '../widgets/custom_button.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class WorkerDetailScreen extends ConsumerWidget {
  final WorkerModel worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(workerReviewsProvider(worker.workerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Hero Header with gradient overlay
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Background gradient
                Container(
                  height: 260,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                          : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                    ),
                  ),
                ),
                // White Card for details
                Container(
                  margin: const EdgeInsets.only(top: 190, left: 20, right: 20),
                  padding: const EdgeInsets.only(top: 80, bottom: 24, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Name
                      Text(
                        worker.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Service badge + verified
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.work_rounded, size: 14, color: Color(0xFFFF9800)),
                                const SizedBox(width: 6),
                                Text(
                                  worker.serviceType,
                                  style: const TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (worker.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Avatar (Half in, half out)
                Positioned(
                  top: 120, // 190 (card top) - 70 (half of 140 height)
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: worker.profileImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(worker.profileImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: worker.profileImage.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Color(0xFFFF9800))
                        : null,
                  ),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _StatItem(
                        icon: Icons.star_rounded,
                        value: worker.rating > 0 ? worker.rating.toStringAsFixed(1) : 'New',
                        label: 'Rating',
                        color: const Color(0xFFFF9800),
                      ),
                      VerticalDivider(
                        color: isDark ? Colors.white12 : Colors.black12,
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      _StatItem(
                        icon: worker.pricingType == 'hourly' ? Icons.timer_rounded : Icons.payments_rounded,
                        value: worker.pricingType == 'hourly'
                            ? 'Rs.${worker.hourlyRate.toStringAsFixed(0)}'
                            : 'Fixed',
                        label: worker.pricingType == 'hourly' ? 'Per Hour' : 'Price',
                        color: Colors.blue,
                      ),
                      VerticalDivider(
                        color: isDark ? Colors.white12 : Colors.black12,
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      _StatItem(
                        icon: Icons.circle,
                        value: worker.availability ? 'Online' : 'Busy',
                        label: 'Status',
                        color: worker.availability ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Detail Cards Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Card
                  _DetailCard(
                    isDark: isDark,
                    icon: Icons.phone_android_rounded,
                    iconColor: Colors.blue,
                    title: 'Contact',
                    content: worker.phone.isEmpty ? 'Phone not available' : worker.phone,
                  ),
                  const SizedBox(height: 14),

                  // Experience Card
                  _DetailCard(
                    isDark: isDark,
                    icon: Icons.work_history_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Experience',
                    content: worker.experience.isEmpty ? 'New to Kaamwala' : worker.experience,
                  ),
                  const SizedBox(height: 14),

                  // Skills Card
                  _DetailCard(
                    isDark: isDark,
                    icon: Icons.build_circle_rounded,
                    iconColor: Colors.purple,
                    title: 'Skills & Expertise',
                    content: worker.skills.isEmpty
                        ? 'General expertise in ${worker.serviceType}'
                        : worker.skills,
                  ),
                  const SizedBox(height: 14),

                  // Location Card
                  _DetailCard(
                    isDark: isDark,
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.teal,
                    title: 'Service Area',
                    content: worker.location.isEmpty ? 'Location N/A' : worker.location,
                  ),
                ],
              ),
            ),
          ),

          // Reviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReviewCard(review: reviews[index]),
                  );
                },
                loading: () => const Center(child: CustomLoadingIndicator()),
                error: (err, _) => Text('Error loading reviews: $err'),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: worker.availability
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'Book Service Now',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(worker: worker),
                      ),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }
}

// Premium stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Detail info card widget
class _DetailCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _DetailCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Review card widget
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: review.userImage.isNotEmpty
                    ? NetworkImage(review.userImage)
                    : null,
                child: review.userImage.isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isEmpty ? 'User' : review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < review.rating.round()
                              ? const Color(0xFFFF9800)
                              : Colors.grey.withValues(alpha: 0.3),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.review,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
