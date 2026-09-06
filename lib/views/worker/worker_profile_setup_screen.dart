import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/worker_controller.dart';
import '../../services/cloudinary_service.dart';
import '../../services/location_service.dart';
import '../../models/service_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'worker_pending_screen.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  State<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final WorkerController _workerController = WorkerController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedServiceType;
  String _pricingType = 'fixed';
  final TextEditingController hourlyRateController = TextEditingController();
  File? image;
  Uint8List? webImage;
  File? nicImage;
  Uint8List? nicWebImage;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isLocating = false;
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null) {
        nameController.text = user.displayName!;
      }

      final worker = await _workerController.getWorkerProfile(user.uid);
      if (worker != null && mounted) {
        setState(() {
          nameController.text = worker.name;
          phoneController.text = worker.phone;
          locationController.text = worker.location;
          nicController.text = worker.nic;
          experienceController.text = worker.experience;
          skillsController.text = worker.skills;
          _selectedServiceType = worker.serviceType.isEmpty
              ? null
              : worker.serviceType;
          _isAvailable = worker.availability;
          _pricingType = worker.pricingType;
          _latitude = worker.latitude;
          _longitude = worker.longitude;
          hourlyRateController.text = worker.hourlyRate > 0
              ? worker.hourlyRate.toString()
              : '';
        });
      }
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      final address = await _locationService.reverseGeocode(pos.latitude, pos.longitude);
      if (address != null && address.trim().isNotEmpty) {
        locationController.text = address;
      } else {
        locationController.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }
      if (mounted) {
        _showMessage('Location detected successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Could not get current location: $e');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    experienceController.dispose();
    skillsController.dispose();
    locationController.dispose();
    nicController.dispose();
    hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => webImage = bytes);
      } else {
        setState(() => image = File(picked.path));
      }
    }
  }

  Future<void> _captureNicImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => nicWebImage = bytes);
      } else {
        setState(() => nicImage = File(picked.path));
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceType == null) {
      _showMessage('Please select a service type');
      return;
    }

    if (image == null && webImage == null) {
      _showMessage('Please capture a live profile photo');
      return;
    }

    if (nicImage == null && nicWebImage == null) {
      _showMessage('Please capture a live NIC photo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';
      if (image != null || webImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(
          imageFile: image,
          webBytes: webImage,
        );
      }

      String nicImageUrl = '';
      if (nicImage != null || nicWebImage != null) {
        nicImageUrl = await _cloudinaryService.uploadImage(
          imageFile: nicImage,
          webBytes: nicWebImage,
        );
      }

      final String workerId = FirebaseAuth.instance.currentUser!.uid;
      final user = FirebaseAuth.instance.currentUser!;

      await _workerController.submitWorkerProfile(
        workerId: workerId,
        name: nameController.text.trim(),
        email: user.email ?? '',
        phone: phoneController.text.trim(),
        profileImage: imageUrl,
        serviceType: _selectedServiceType!,
        experience: experienceController.text.trim(),
        skills: skillsController.text.trim(),
        location: locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        availability: _isAvailable,
        nic: nicController.text.trim(),
        nicImageUrl: nicImageUrl,
        pricingType: _pricingType,
        hourlyRate: double.tryParse(hourlyRateController.text.trim()) ?? 0.0,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerPendingScreen()),
      );
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
      appBar: AppBar(title: const Text('Setup Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your profile to start getting jobs',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

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
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        backgroundImage: kIsWeb && webImage != null
                            ? MemoryImage(webImage!) as ImageProvider
                            : (!kIsWeb && image != null
                                  ? FileImage(image!)
                                  : null),
                        child: image == null && webImage == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: isDark ? Colors.white24 : Colors.black26,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ImagePickButton(
                          onPressed: _captureImage,
                          icon: Icons.camera_alt_rounded,
                          label: 'Take Live Photo',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              CustomTextField(
                controller: nameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
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
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.trim().length != 11) {
                    return 'Phone number must be 11 digits';
                  }
                  return null;
                },
              ),

              const Text(
                'Service Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedServiceType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work_rounded, size: 22),
                  hintText: 'Select your service',
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
                ),
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                items: serviceCategoryNames
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedServiceType = value),
                validator: (value) =>
                    value == null ? 'Please select a service' : null,
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: nicController,
                label: 'CNIC Number',
                hintText: '13 digits (no dashes)',
                prefixIcon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter CNIC';
                  }
                  if (value.trim().length != 13) {
                    return 'CNIC must be 13 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Live NIC Photo (Front)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 1,
                        ),
                        image: kIsWeb && nicWebImage != null
                            ? DecorationImage(
                                image: MemoryImage(nicWebImage!),
                                fit: BoxFit.cover,
                              )
                            : (!kIsWeb && nicImage != null
                                ? DecorationImage(
                                    image: FileImage(nicImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: nicImage == null && nicWebImage == null
                          ? Icon(
                              Icons.credit_card_rounded,
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.black26,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _ImagePickButton(
                      onPressed: _captureNicImage,
                      icon: Icons.camera_alt_rounded,
                      label: 'Capture Live NIC Photo',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Pricing Structure',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PricingTypeCard(
                      label: 'Fixed / Quote',
                      icon: Icons.payments_rounded,
                      isSelected: _pricingType == 'fixed',
                      onTap: () => setState(() => _pricingType = 'fixed'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PricingTypeCard(
                      label: 'Hourly Rate',
                      icon: Icons.timer_rounded,
                      isSelected: _pricingType == 'hourly',
                      onTap: () => setState(() => _pricingType = 'hourly'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_pricingType == 'hourly') ...[
                CustomTextField(
                  controller: hourlyRateController,
                  label: 'Hourly Rate (Rs.)',
                  hintText: 'Enter amount per hour',
                  prefixIcon: Icons.price_change_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_pricingType == 'hourly' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter your hourly rate';
                    }
                    return null;
                  },
                ),
              ],

              CustomTextField(
                controller: experienceController,
                label: 'Experience',
                hintText: 'e.g. 5 Years',
                prefixIcon: Icons.history_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter experience';
                  }
                  return null;
                },
              ),

              CustomTextField(
                controller: skillsController,
                label: 'Specific Skills',
                hintText: 'List your specialties...',
                prefixIcon: Icons.auto_awesome_rounded,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your skills';
                  }
                  return null;
                },
              ),

              CustomTextField(
                controller: locationController,
                label: 'Service Location',
                hintText: 'Area, City (e.g. Gulberg, Lahore)',
                prefixIcon: Icons.location_on_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isLocating ? null : _detectCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(
                    _isLocating ? 'Detecting GPS...' : 'Use Current GPS Location',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Available for Work',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isAvailable
                        ? 'You are visible to customers'
                        : 'You are currently hidden',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  value: _isAvailable,
                  onChanged: (value) => setState(() => _isAvailable = value),
                  activeThumbColor: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: 'Save & Continue',
                onPressed: _submitProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9800).withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF9800) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFFF9800)
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFFFF9800)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
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
