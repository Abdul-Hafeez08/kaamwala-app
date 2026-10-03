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
import 'admin_revenue_screen.dart';
import '../../providers/admin_provider.dart';
import '../../providers/complaint_provider.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminWorkersScreen(),
    const AdminJobsScreen(),
    const AdminComplaintsScreen(),
    const AdminServicesScreen(),
    const AdminRevenueScreen(),
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
    final currentIndex = ref.watch(adminBottomNavIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;

        if (isWeb) {
          return Scaffold(
            body: Row(
              children: [
                // Permanent Left Sidebar
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sidebar Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF9800),
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.transparent,
                                child: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 32,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            currentUserAsync.when(
                              data: (user) => Text(
                                user?.email ?? 'admin@kaamwala.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              loading: () => const Text('Loading...'),
                              error: (_, _) => const Text('admin@kaamwala.com'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Navigation Items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          children: [
                            _SidebarItem(
                              icon: Icons.dashboard_rounded,
                              label: 'Dashboard',
                              isSelected: currentIndex == 0,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 0,
                            ),
                            _SidebarItem(
                              icon: Icons.group_rounded,
                              label: 'Users',
                              isSelected: currentIndex == 1,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 1,
                            ),
                            _SidebarItem(
                              icon: Icons.engineering_rounded,
                              label: 'Workers',
                              isSelected: currentIndex == 2,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 2,
                            ),
                            _SidebarItem(
                              icon: Icons.assignment_rounded,
                              label: 'Jobs',
                              isSelected: currentIndex == 3,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 3,
                            ),
                            _SidebarItem(
                              icon: Icons.sms_rounded,
                              label: 'Complaints (SMS)',
                              badge: pendingComplaintsCount > 0 ? pendingComplaintsCount.toString() : null,
                              isSelected: currentIndex == 4,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 4,
                            ),
                            _SidebarItem(
                              icon: Icons.category_rounded,
                              label: 'Services Management',
                              isSelected: currentIndex == 5,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 5,
                            ),
                            _SidebarItem(
                              icon: Icons.analytics_rounded,
                              label: 'Revenue Analytics',
                              isSelected: currentIndex == 6,
                              onTap: () => ref.read(adminBottomNavIndexProvider.notifier).state = 6,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Logout
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            foregroundColor: Colors.red,
                            overlayColor: Colors.red.withValues(alpha: 0.15),
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Scaffold(
                    body: IndexedStack(
                      index: currentIndex,
                      children: _screens,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout
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
                  _DrawerItem(
                    icon: Icons.analytics_rounded,
                    label: 'Revenue Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminRevenueScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 24, endIndent: 24),
                  const Spacer(),
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
            body: IndexedStack(
              index: currentIndex > 4 ? 0 : currentIndex,
              children: _screens.sublist(0, 5),
            ),
            bottomNavigationBar: CurvedBottomNavBar(
              currentIndex: currentIndex > 4 ? 0 : currentIndex,
              onTap: (index) => ref.read(adminBottomNavIndexProvider.notifier).state = index,
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
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? const Color(0xFFFF9800)
        : (isDark ? Colors.white70 : Colors.black54);
    final bgColor = isSelected
        ? const Color(0xFFFF9800).withValues(alpha: 0.1)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
