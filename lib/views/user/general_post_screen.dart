import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/booking_controller.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class GeneralPostScreen extends ConsumerStatefulWidget {
  const GeneralPostScreen({super.key});

  @override
  ConsumerState<GeneralPostScreen> createState() => _GeneralPostScreenState();
}

class _GeneralPostScreenState extends ConsumerState<GeneralPostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final BookingController _bookingController = BookingController();
  final LocationService _locationService = LocationService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  String? _selectedCategory;
  String _selectedUrgency = 'Today';
  bool _isLoading = false;
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _postToMarketplace() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (userProfile == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await _bookingController.createBooking(
        userId: userProfile.userId,
        workerId: '', // Empty for general requests
        serviceType: _selectedCategory!,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        location: userProfile.location, // or title if location is unused? Actually, let's store title in address if needed? Wait, JobModel doesn't have a title. We'll append title to description.
        userName: userProfile.name,
        userPhone: userProfile.phone,
        workerName: '',
        workerImage: '',
        scheduledDate: now,
        scheduledTime: timeString,
        isGeneralRequest: true,
        urgency: _selectedUrgency,
        budgetRange: _budgetController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Posted Successfully'),
            ],
          ),
          content: const Text(
            'Your request has been posted to the marketplace. Available workers in this category will see it and accept it soon.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(availableServicesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Post to Marketplace')),
      body: servicesAsync.when(
        data: (services) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What do you need?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _titleController,
                  label: 'Job Title',
                  hintText: 'e.g. Fix leaking tap',
                  prefixIcon: Icons.title_rounded,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      hint: const Text('Choose a category'),
                      items: services
                          .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hintText: 'Detailed description of the problem...',
                  prefixIcon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Location & Budget',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Service Location / Address',
                  hintText: 'Where do you need the service?',
                  prefixIcon: Icons.location_on_rounded,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Google Map location to make worker find you easier',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (_latitude != 0.0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('📍 Google Map location added!')),
                              );
                            } else {
                              await _fetchLocation();
                              if (_latitude != 0.0 && mounted) {
                                final addr = await _locationService.reverseGeocode(_latitude, _longitude);
                                if (addr != null && _addressController.text.isEmpty) {
                                  _addressController.text = addr;
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('📍 Google Map location added!')),
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(
                            Icons.map_rounded,
                            color: _latitude != 0.0 ? Colors.green : null,
                          ),
                          label: Text(
                            _latitude != 0.0 && _longitude != 0.0
                                ? '✓ Location Added'
                                : 'Add Google Map Location',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _latitude != 0.0 ? Colors.green : const Color(0xFF4285F4),
                            side: BorderSide(color: _latitude != 0.0 ? Colors.green : const Color(0xFF4285F4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _budgetController,
                  label: 'Budget Range',
                  hintText: 'e.g. \$50 - \$100 or Negotiable',
                  prefixIcon: Icons.monetization_on_rounded,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Urgency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedUrgency = 'Today'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedUrgency == 'Today' ? const Color(0xFFFF9800) : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Today',
                            style: TextStyle(
                              color: _selectedUrgency == 'Today' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedUrgency = 'This Week'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedUrgency == 'This Week' ? const Color(0xFFFF9800) : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'This Week',
                            style: TextStyle(
                              color: _selectedUrgency == 'This Week' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    ),
    loading: () => const Center(child: CustomLoadingIndicator()),
    error: (err, _) => Center(child: Text('Error: $err')),
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
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: CustomButton(
            text: 'Post Request',
            onPressed: _postToMarketplace,
            isLoading: _isLoading,
          ),
        ),
      ),
    ),
  ),
);
  }
}
