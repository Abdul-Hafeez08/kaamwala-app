import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaamwala/providers/complaint_provider.dart';
import 'package:kaamwala/providers/user_provider.dart';
import 'package:kaamwala/models/user_model.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class UserComplaintScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const UserComplaintScreen({super.key, required this.user});

  @override
  ConsumerState<UserComplaintScreen> createState() =>
      _UserComplaintScreenState();
}

class _UserComplaintScreenState extends ConsumerState<UserComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedWorkerId;
  String? _selectedWorkerName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final complaintController = ComplaintController();
      await complaintController.submitComplaint(
        userId: widget.user.userId,
        userName: widget.user.name,
        userEmail: widget.user.email,
        workerId: _selectedWorkerId,
        workerName: _selectedWorkerName,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complaint submitted successfully. We will look into it!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workersAsync = ref.watch(allApprovedWorkersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Complaints')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit a Complaint',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let us know what went wrong, and our admin team will investigate it as soon as possible.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              // Worker Selection
              const Text(
                'Select Worker (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              workersAsync.when(
                data: (workers) => DropdownButtonFormField<String>(
                  initialValue: _selectedWorkerId,
                  decoration: InputDecoration(
                    hintText: 'Select a worker you have an issue with',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('General Complaint (No specific worker)'),
                    ),
                    ...workers.map(
                      (worker) => DropdownMenuItem<String>(
                        value: worker.workerId,
                        child: Text('${worker.name} (${worker.serviceType})'),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedWorkerId = val;
                      if (val != null) {
                        _selectedWorkerName = workers
                            .firstWhere((w) => w.workerId == val)
                            .name;
                      } else {
                        _selectedWorkerName = null;
                      }
                    });
                  },
                ),
                loading: () =>
                    const Center(child: CustomLoadingIndicator(size: 30)),
                error: (_, _) => const Text('Error loading workers'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Subject',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a subject'
                    : null,
                decoration: InputDecoration(
                  hintText: 'e.g., Worker didn\'t arrive on time',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Complaint Message',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please describe your issue'
                    : null,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Provide details about your complaint...',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CustomLoadingIndicator(
                            size: 20,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Complaint',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
