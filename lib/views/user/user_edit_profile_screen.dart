import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../controllers/user_controller.dart';
import '../../services/cloudinary_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_loading_indicator.dart';

class UserEditProfileScreen extends StatefulWidget {
  final UserModel user;

  const UserEditProfileScreen({super.key, required this.user});

  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _locationController;

  final UserController _userController = UserController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  String _profileImageUrl = '';
  File? _mobileImageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);
    _locationController = TextEditingController(text: widget.user.location);
    _profileImageUrl = widget.user.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userController.updateUserProfile(widget.user.userId, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'location': _locationController.text.trim(),
        'profileImage': _profileImageUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: SelectableText(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
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
                                              ? NetworkImage(_profileImageUrl)
                                              : null))),
                        child: _isUploadingImage
                            ? const CustomLoadingIndicator(size: 40)
                            : (_profileImageUrl.isEmpty &&
                                      _mobileImageFile == null &&
                                      _webImageBytes == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    )
                                  : null),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ImagePickButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                        ),
                        const SizedBox(width: 16),
                        _ImagePickButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icons.camera_alt_rounded,
                          label: 'Camera',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              CustomTextField(
                controller: _nameController,
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
                controller: _phoneController,
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
                controller: _addressController,
                label: 'Full Address',
                hintText: 'House #, Street, Area',
                prefixIcon: Icons.home_rounded,
              ),
              CustomTextField(
                controller: _locationController,
                label: 'City / Region',
                hintText: 'e.g. Lahore, Pakistan',
                prefixIcon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Save Changes',
            onPressed: _saveProfile,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}

class _ImagePickButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _ImagePickButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF9800),
        side: const BorderSide(color: Color(0xFFFF9800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
