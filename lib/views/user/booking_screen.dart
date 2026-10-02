import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final WorkerModel worker;

  const BookingScreen({super.key, required this.worker});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final BookingController _bookingController = BookingController();
  final ChatController _chatController = ChatController();
  final LocationService _locationService = LocationService();

  final TextEditingController _budgetController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _messageController.dispose();
    _budgetController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (userProfile == null) {
      _showMessage('Please login again');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      await _bookingController.createBooking(
        userId: userProfile.userId,
        workerId: widget.worker.workerId,
        serviceType: widget.worker.serviceType,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        location: userProfile.location,
        userName: userProfile.name,
        userPhone: userProfile.phone,
        workerName: widget.worker.name,
        workerImage: widget.worker.profileImage,
        scheduledDate: _selectedDate,
        scheduledTime: timeString,
        budgetRange: _budgetController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (_messageController.text.trim().isNotEmpty) {
        await _chatController.sendInitialMessageOrGetChat(
          userId: userProfile.userId,
          workerId: widget.worker.workerId,
          userName: userProfile.name,
          userImage: userProfile.profileImage,
          workerName: widget.worker.name,
          workerImage: widget.worker.profileImage,
          initialMessageText: _messageController.text.trim(),
        );
      }

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
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Booking Confirmed'),
            ],
          ),
          content: const Text(
            'Your booking has been placed successfully. The worker will respond soon.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
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
    final worker = widget.worker;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: worker.profileImage.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(worker.profileImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      ),
                      child: worker.profileImage.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Color(0xFFFF9800),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            worker.serviceType,
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Select Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SchedulePicker(
                      onTap: _pickDate,
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SchedulePicker(
                      onTap: _pickTime,
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: _selectedTime.format(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Service Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Service Location / Address',
                hintText: 'Enter your full address',
                prefixIcon: Icons.location_on_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
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
                label: 'Proposed Budget',
                hintText: 'e.g. Rs. 500 or Negotiable',
                prefixIcon: Icons.monetization_on_rounded,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Describe the Problem',
                hintText: 'What service do you need? Any specific issue?',
                prefixIcon: Icons.description_rounded,
                suffixIcon: Icons.mic_rounded,
                onSuffixTap: () {
                  _showMessage('Voice recording simulated');
                },
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe what you need';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _messageController,
                label: 'Message to Worker (Optional)',
                hintText: 'Send a quick message to the worker...',
                prefixIcon: Icons.chat_bubble_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
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
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: CustomButton(
            text: 'Confirm Booking',
            onPressed: _confirmBooking,
            isLoading: _isLoading,
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _SchedulePicker extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final String value;

  const _SchedulePicker({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFFFF9800)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
