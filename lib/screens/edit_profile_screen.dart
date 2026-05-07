import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _otpController;

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isPhoneVerified = true;
  String _originalPhone = '';

  @override
  void initState() {
    super.initState();
    _originalPhone = widget.profileData['phone_number'] ?? '';
    _fullNameController = TextEditingController(text: widget.profileData['full_name']);
    _phoneController = TextEditingController(text: _originalPhone.replaceFirst('+91', ''));
    _otpController = TextEditingController();

    _phoneController.addListener(() {
      final currentPhone = '+91${_phoneController.text}';
      if (currentPhone != _originalPhone) {
        if (_isPhoneVerified) {
          setState(() {
            _isPhoneVerified = false;
            _otpSent = false;
          });
        }
      } else {
        if (!_isPhoneVerified) {
          setState(() {
            _isPhoneVerified = true;
            _otpSent = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.sendOTP('+91${_phoneController.text}');
      if (result['success']) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to send OTP'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.verifyOTP(
        '+91${_phoneController.text}',
        _otpController.text,
      );
      if (result['success']) {
        setState(() {
          _isPhoneVerified = true;
          _otpSent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Invalid OTP'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final updatedData = {
      'full_name': _fullNameController.text.trim(),
      'phone_number': '+91${_phoneController.text.trim()}',
    };

    try {
      final result = await _apiService.updateProfile(updatedData);
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personal details updated!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Update failed'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Personal Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) => (value == null || value.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildPhoneField(),
                    if (_otpSent && !_isPhoneVerified) ...[
                      const SizedBox(height: 20),
                      _buildOtpField(),
                    ],
                    const SizedBox(height: 48),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixIcon: Icon(icon, color: const Color(0xFFE65100), size: 22),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(
      controller: _phoneController,
      label: 'Phone Number',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
      validator: (value) => (value?.length != 10) ? 'Enter 10-digit number' : null,
      suffix: _isPhoneVerified
          ? const Icon(Icons.check_circle, color: Colors.green)
          : TextButton(
              onPressed: _otpSent ? null : _sendOTP,
              child: Text(_otpSent ? 'Sent' : 'Verify', style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildOtpField() {
    return _buildTextField(
      controller: _otpController,
      label: 'Enter 6-Digit OTP',
      icon: Icons.lock_clock_outlined,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      suffix: TextButton(
        onPressed: _verifyOTP,
        child: const Text('Verify OTP', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
