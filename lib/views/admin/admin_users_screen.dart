import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

import 'package:intl/intl.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allUsersProvider);
        },
        child: usersAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No registered users found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 140,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      margin: EdgeInsets.zero,
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF9800),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: user.profileImage.isNotEmpty
                                ? NetworkImage(user.profileImage)
                                : null,
                            child: user.profileImage.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 30,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name.isNotEmpty
                                    ? user.name
                                    : 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_rounded,
                                    size: 14,
                                    color: Color(0xFFFF9800),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 14,
                                    color: Color(0xFFFF9800),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    user.phone.isNotEmpty
                                        ? user.phone
                                        : 'No phone provided',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'MEMBER SINCE: ${DateFormat('MMM dd, yyyy').format(user.createdAt).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                  },
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
      ),
    );
  }
}
