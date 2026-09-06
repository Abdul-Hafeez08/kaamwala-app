import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'user_edit_profile_screen.dart';
import 'user_complaint_screen.dart';
import '../widgets/custom_button.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Unable to load profile'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 12,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 4,
                        offset: const Offset(0, 25),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFFF9800),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                              backgroundImage: user.profileImage.isNotEmpty
                                  ? NetworkImage(user.profileImage)
                                  : null,
                              child: user.profileImage.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 56, color: Color(0xFFFF9800))
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 4,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserEditProfileScreen(user: user),
                                  ),
                                ).then(
                                  (_) => ref.invalidate(userProfileProvider),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Settings List
                _SettingsGroup(
                  title: 'Personal Information',
                  children: [
                    _SettingsTile(
                      icon: Icons.phone_rounded,
                      title: 'Phone',
                      subtitle: user.phone.isEmpty ? 'Not set' : user.phone,
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_rounded,
                      title: 'Location',
                      subtitle: user.location.isEmpty
                          ? 'Not set'
                          : user.location,
                    ),
                    _SettingsTile(
                      icon: Icons.home_rounded,
                      title: 'Home Address',
                      subtitle: user.address.isEmpty ? 'Not set' : user.address,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _SettingsGroup(
                  title: 'Appearance',
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: const Color(0xFFFF9800),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isDark ? 'Dark theme enabled' : 'Light theme enabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
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
                  ],
                ),
                const SizedBox(height: 24),

                _SettingsGroup(
                  title: 'Account',
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Help & Complaints',
                      subtitle: 'Submit a ticket',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserComplaintScreen(user: user),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.security_rounded,
                      title: 'Security',
                      subtitle: 'Password and privacy',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Logout Button
                CustomButton(
                  text: 'Sign Out',
                  onPressed: () => _handleLogout(context, ref),
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  textColor: Colors.red,
                  icon: Icons.logout_rounded,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF9800),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF9800), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded, size: 20)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
