import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/worker_controller.dart';
import '../../providers/worker_provider.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import 'worker_profile_setup_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerStream = ref.watch(workerProfileStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return workerStream.when(
      data: (worker) {
        if (worker == null) {
          return const Scaffold(body: Center(child: Text('Profile not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Account Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkerProfileSetupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        backgroundImage: worker.profileImage.isNotEmpty
                            ? NetworkImage(worker.profileImage)
                            : null,
                        child: worker.profileImage.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: isDark ? Colors.white24 : Colors.black26,
                              )
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    worker.serviceType,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                _buildInfoSection(context, 'Business Details', [
                  _DetailRow(
                    Icons.email_rounded,
                    'Email Address',
                    worker.email,
                  ),
                  _DetailRow(
                    Icons.phone_iphone_rounded,
                    'Phone Number',
                    worker.phone,
                  ),
                  _DetailRow(
                    Icons.work_history_rounded,
                    'Experience',
                    worker.experience,
                  ),
                  _DetailRow(
                    Icons.auto_awesome_rounded,
                    'Key Skills',
                    worker.skills,
                  ),
                  _DetailRow(
                    Icons.location_on_rounded,
                    'Base Location',
                    worker.location,
                  ),
                ]),

                const SizedBox(height: 24),

                _buildInfoSection(context, 'Account Status', [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Open to Work / Active',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      worker.availability
                          ? '🟢 Visible to nearby customers on map'
                          : '🔴 Offline / Hidden from search',
                      style: TextStyle(
                        color: worker.availability ? Colors.green : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Switch(
                      value: worker.availability,
                      activeThumbColor: Colors.green,
                      onChanged: (value) async {
                        await WorkerController().updateAvailability(
                          worker.workerId,
                          value,
                        );
                        // If turning online and lat/lng are 0.0, try to update location in background
                        if (value && (worker.latitude == 0.0 || worker.longitude == 0.0)) {
                          try {
                            final pos = await LocationService().getCurrentPosition();
                            await FirestoreService().updateWorkerLocation(
                              worker.workerId,
                              pos.latitude,
                              pos.longitude,
                            );
                          } catch (_) {}
                        }
                      },
                    ),
                  ),
                  _DetailRow(
                    Icons.location_searching_rounded,
                    'Coordinates Status',
                    (worker.latitude != 0.0 && worker.longitude != 0.0)
                        ? 'Active (${worker.latitude.toStringAsFixed(2)}, ${worker.longitude.toStringAsFixed(2)})'
                        : 'Not Set (Use edit profile to set GPS)',
                    color: (worker.latitude != 0.0 && worker.longitude != 0.0)
                        ? Colors.green
                        : Colors.orange,
                  ),
                  _DetailRow(
                    Icons.verified_user_rounded,
                    'Verification Status',
                    worker.approvalStatus.toUpperCase(),
                    color: worker.approvalStatus == 'approved'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ]),

                const SizedBox(height: 24),



                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      await AuthController().signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Logout Account',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CustomLoadingIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: SelectableText('Error: $error'))),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _DetailRow(this.icon, this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFFF9800)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not Provided' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color ?? (isDark ? Colors.white : Colors.black87),
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
