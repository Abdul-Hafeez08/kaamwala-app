import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../providers/worker_provider.dart';
import '../auth/login_screen.dart';
import 'worker_dashboard_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class WorkerPendingScreen extends ConsumerStatefulWidget {
  const WorkerPendingScreen({super.key});

  @override
  ConsumerState<WorkerPendingScreen> createState() => _WorkerPendingScreenState();
}

class _WorkerPendingScreenState extends ConsumerState<WorkerPendingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerStream = ref.watch(workerProfileStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return workerStream.when(
      data: (worker) {
        if (worker != null && worker.approvalStatus == 'approved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
            );
          });
        }

        final bool isRejected = worker?.approvalStatus == 'rejected';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: isRejected ? const AlwaysStoppedAnimation(1.0) : _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: (isRejected ? Colors.red : const Color(0xFFFF9800))
                          .withValues(alpha: isDark ? 0.15 : 0.1),
                      shape: BoxShape.circle,
                      boxShadow: isRejected ? [] : [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: isDark ? 0.4 : 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                      border: Border.all(
                        color: (isRejected ? Colors.red : const Color(0xFFFF9800))
                            .withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isRejected
                          ? Icons.error_outline_rounded
                          : Icons.pending_actions_rounded,
                      size: 80,
                      color: isRejected ? Colors.red : const Color(0xFFFF9800),
                      shadows: isRejected ? [] : [
                        const Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  isRejected ? 'Profile Rejected' : 'Account Under Review',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isRejected
                      ? 'Your profile has been rejected by the admin. Please contact support to resolve this issue.'
                      : 'Aapka account review ho raha hai,\n24-48 hours mein approve ho jayega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 240,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRejected
                          ? Colors.red
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      foregroundColor: isRejected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      side: isRejected ? BorderSide.none : BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: isRejected ? 4 : 0,
                    ),
                    child: const Text(
                      'Logout Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
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
}
