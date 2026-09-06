import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/curved_bottom_nav.dart';
import 'user_home_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../widgets/user_drawer.dart';
import '../../providers/chat_provider.dart';

class UserMainScreen extends ConsumerStatefulWidget {
  const UserMainScreen({super.key});

  @override
  ConsumerState<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends ConsumerState<UserMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UserHomeScreen(),
    const UserBookingsScreen(),
    const ChatListScreen(isWorker: false),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(totalUnreadCountUserProvider);

    return Scaffold(
      drawer: const UserDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const CurvedNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          const CurvedNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings'),
          CurvedNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Messages',
            badge: unreadCount > 0 ? Text(unreadCount.toString()) : null,
          ),
          const CurvedNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}
