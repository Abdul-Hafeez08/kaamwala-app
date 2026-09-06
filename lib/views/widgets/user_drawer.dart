import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaamwala/providers/auth_provider.dart';
import 'package:kaamwala/providers/user_provider.dart';
import 'package:kaamwala/views/auth/login_screen.dart';
import 'package:kaamwala/views/user/user_complaint_screen.dart';
import 'package:kaamwala/providers/theme_provider.dart';
import 'custom_loading_indicator.dart';

class UserDrawer extends ConsumerWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      child: Column(
        children: [
          // Header
          userAsync.when(
            data: (user) => Container(
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
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    backgroundImage: (user?.profileImage ?? '').isNotEmpty
                        ? NetworkImage(user!.profileImage)
                        : null,
                    child: (user?.profileImage ?? '').isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CustomLoadingIndicator()),
            ),
            error: (_, _) => const SizedBox(
              height: 200,
              child: Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Navigation Items
          _DrawerTile(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerTile(
            icon: Icons.support_agent_rounded,
            label: 'Complaints & Support',
            onTap: () {
              Navigator.pop(context);
              final user = ref.read(userProfileProvider).value;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserComplaintScreen(user: user),
                  ),
                );
              }
            },
          ),
          // Dark Mode Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: const Color(0xFFFF9800),
                    size: 20,
                  ),
                ),
                title: Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: const Color(0xFFFF9800),
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                          val ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
              ),
            ),
          ),

          const Spacer(),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(firebaseAuthServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF9800)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
