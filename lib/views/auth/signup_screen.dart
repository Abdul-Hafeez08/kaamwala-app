import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../services/cloudinary_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_loading_indicator.dart';
import 'login_screen.dart';
import '../worker/worker_profile_setup_screen.dart';
import '../user/user_main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthController _authController = AuthController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  String _selectedRole = 'user';
  bool _isLoading = false;

  // Image handling
  String _profileImageUrl = '';
  File? _mobileImageFile;
  Uint8List? _webImageBytes;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() => _isUploadingImage = true);

        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _mobileImageFile = null;
          });
          final url = await _cloudinaryService.uploadImage(webBytes: bytes);
          setState(() => _profileImageUrl = url);
        } else {
          final file = File(picked.path);
          setState(() {
            _mobileImageFile = file;
            _webImageBytes = null;
          });
          final url = await _cloudinaryService.uploadImage(imageFile: file);
          setState(() => _profileImageUrl = url);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectableText('Upload Error: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authController.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        role: _selectedRole,
        profileImage: _profileImageUrl,
      );

      if (!mounted) return;

      if (_selectedRole == 'worker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkerProfileSetupScreen()),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserMainScreen()),
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
                    : [const Color(0xFFFFF3E0), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Glowing Orb - Top Right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF9800).withValues(alpha: isDark ? 0.15 : 0.3),
              ),
            ),
          ),
          // Glowing Orb - Bottom Left
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB74D).withValues(alpha: isDark ? 0.1 : 0.2),
              ),
            ),
          ),
          // Glowing Orb - Mid Right (extra depth)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFCC80).withValues(alpha: isDark ? 0.08 : 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join the Kaamwala community',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Profile Image Picker
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFF9800),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 48,
                                        backgroundColor: isDark
                                            ? const Color(0xFF1E1E1E)
                                            : const Color(0xFFF8F8F8),
                                        backgroundImage: _isUploadingImage
                                            ? null
                                            : (_webImageBytes != null
                                                  ? MemoryImage(_webImageBytes!)
                                                        as ImageProvider
                                                  : (_mobileImageFile != null
                                                        ? FileImage(_mobileImageFile!)
                                                        : (_profileImageUrl.isNotEmpty
                                                              ? NetworkImage(
                                                                  _profileImageUrl,
                                                                )
                                                              : null))),
                                        child: _isUploadingImage
                                            ? const CustomLoadingIndicator(size: 30)
                                            : (_profileImageUrl.isEmpty &&
                                                      _mobileImageFile == null &&
                                                      _webImageBytes == null
                                                  ? Icon(
                                                      Icons.add_a_photo_rounded,
                                                      size: 28,
                                                      color: isDark
                                                          ? Colors.white38
                                                          : Colors.grey.shade400,
                                                    )
                                                  : null),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildImagePickerButton(
                                          icon: Icons.photo_library_rounded,
                                          label: 'Gallery',
                                          onTap: () => _pickImage(ImageSource.gallery),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildImagePickerButton(
                                          icon: Icons.camera_alt_rounded,
                                          label: 'Camera',
                                          onTap: () => _pickImage(ImageSource.camera),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Input Fields
                              CustomTextField(
                                controller: nameController,
                                label: 'Full Name',
                                hintText: 'Enter your name',
                                prefixIcon: Icons.person_rounded,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),

                              CustomTextField(
                                controller: emailController,
                                label: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              CustomTextField(
                                controller: phoneController,
                                label: 'Phone Number',
                                hintText: '03XXXXXXXXX',
                                prefixIcon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (value.length != 11) {
                                    return 'Phone number must be 11 digits';
                                  }
                                  return null;
                                },
                              ),

                              CustomTextField(
                                controller: passwordController,
                                label: 'Password',
                                hintText: 'At least 6 characters',
                                prefixIcon: Icons.lock_rounded,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Role Dropdown
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'I am a',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedRole,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.badge_rounded, size: 22),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF1E1E1E)
                                            : const Color(0xFFF8F8F8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFF9800),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      dropdownColor: isDark
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'user',
                                          child: Text('User (Customer)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'worker',
                                          child: Text('Worker (Service Provider)'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _selectedRole = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Signup Button with glow
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                                child: CustomButton(
                                  text: 'Create Account',
                                  onPressed: _handleSignup,
                                  isLoading: _isLoading,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.4),
            ),
            color: const Color(0xFFFF9800).withValues(alpha: isDark ? 0.1 : 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFFFF9800)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
