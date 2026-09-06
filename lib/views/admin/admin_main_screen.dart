import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../widgets/curved_bottom_nav.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_workers_screen.dart';
import 'admin_services_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_complaints_screen.dart';
import '../../providers/complaint_provider.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminWorkersScreen(),
    const AdminJobsScreen(),
    const AdminComplaintsScreen(),
  ];

  Future<void> _logout() async {
    final authService = ref.read(firebaseAuthServiceProvider);
    await authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserAsync = ref.watch(currentUserProvider);
    final pendingComplaintsCount = ref.watch(pendingComplaintsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        child: Column(
          children: [
            // Drawer Header with admin email
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  currentUserAsync.when(
                    data: (user) => Text(
                      user?.email ?? 'admin@kaamwala.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    loading: () => Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    error: (_, _) => Text(
                      'admin@kaamwala.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Services Management
            _DrawerItem(
              icon: Icons.category_rounded,
              label: 'Services Management',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminServicesScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 1, indent: 24, endIndent: 24),

            const Spacer(),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red,
                    overlayColor: Colors.red.withValues(alpha: 0.15),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const CurvedNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          const CurvedNavItem(
            icon: Icons.group_outlined,
            activeIcon: Icons.group_rounded,
            label: 'Users',
          ),
          const CurvedNavItem(
            icon: Icons.engineering_outlined,
            activeIcon: Icons.engineering_rounded,
            label: 'Workers',
          ),
          const CurvedNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Jobs',
          ),
          CurvedNavItem(
            icon: Icons.sms_outlined,
            activeIcon: Icons.sms_rounded,
            label: 'SMS',
            badge: pendingComplaintsCount > 0
                ? Text(pendingComplaintsCount.toString())
                : null,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF9800), size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
      onTap: onTap,
    );
  }
}
