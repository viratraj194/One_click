import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _aadhaarOtpController = TextEditingController();
  
  // Dynamic list for Emergency Family Contacts
  final List<Map<String, TextEditingController>> _emergencyContacts = [];
  
  String? _selectedBloodGroup;
  
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  bool _isLoading = false;
  bool _isPhoneVerified = false;
  bool _otpSent = false;
  bool _isAadhaarVerified = false;
  bool _isAadhaarOtpSent = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_isPhoneVerified || _otpSent) {
        setState(() {
          _isPhoneVerified = false;
          _otpSent = false;
          _otpController.clear();
          // Reset Aadhaar state if phone changes
          _isAadhaarVerified = false;
          _isAadhaarOtpSent = false;
          _aadhaarOtpController.clear();
        });
      }
    });
    // Add the first primary contact by default
    _addEmergencyContact();
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
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
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
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestAadhaarOTP() async {
    if (_aadhaarController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 12-digit Aadhaar number.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.requestAadhaarOTP(_aadhaarController.text);
      if (result['success']) {
        setState(() => _isAadhaarOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aadhaar OTP sent! (Mock: 998877)'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAadhaar() async {
    // Explicit null check as requested, and length check
    if (_aadhaarOtpController.text.isEmpty || _aadhaarOtpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit Aadhaar OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Mock Logic: check for '998877'
    if (_aadhaarOtpController.text == '998877') {
      setState(() {
        _isAadhaarVerified = true;
        _isAadhaarOtpSent = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aadhaar verified successfully!'), backgroundColor: Colors.green),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Aadhaar OTP.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.register(
        username: _usernameController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        phone: '+91${_phoneController.text}',
        bloodGroup: _selectedBloodGroup!,
        aadhaar: _aadhaarController.text,
      );

      if (result['success']) {
        // Save the authentication token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result['data']['token']);
        
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addEmergencyContact() {
    setState(() {
      _emergencyContacts.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _addressController.dispose();
    _otpController.dispose();
    _aadhaarOtpController.dispose();
    for (var contact in _emergencyContacts) {
      contact['name']?.dispose();
      contact['phone']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Your Secure Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your information is encrypted end-to-end and used only for emergency response.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Account Details
                    _buildInputField(
                      label: 'Username',
                      hint: 'Choose a unique username',
                      icon: Icons.account_circle_outlined,
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Password',
                      hint: 'Enter a secure password',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    
                    // Phone Number Step
                    _buildInputField(
                      label: 'Phone Number',
                      hint: '10-digit mobile number',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      suffix: _isPhoneVerified 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: (_isLoading || _otpSent) ? null : _sendOTP,
                            child: Text(
                              _otpSent ? 'OTP Sent' : 'Get OTP', 
                              style: TextStyle(
                                color: (_isLoading || _otpSent) ? Colors.grey : const Color(0xFFE65100), 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                    ),
                    
                    // OTP Input Step (Conditional)
                    if (_otpSent && !_isPhoneVerified) ...[
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Enter 6-Digit OTP',
                        hint: '000000',
                        icon: Icons.lock_clock_outlined,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        suffix: TextButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          child: const Text(
                            'Verify', 
                            style: TextStyle(
                              color: Color(0xFFE65100), 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    const Divider(),
                    const SizedBox(height: 32),

                    // Profile Fields - Disabled until verified
                    Opacity(
                      opacity: _isPhoneVerified ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: !_isPhoneVerified,
                        child: Column(
                          children: [
                            // Full Name
                            _buildInputField(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              icon: Icons.person_outline,
                              controller: _nameController,
                            ),
                            const SizedBox(height: 20),
                            
                            // Aadhaar Number Step
                            _buildAadhaarField(),
                            
                            // Aadhaar OTP Step (Conditional)
                            if (_isAadhaarOtpSent && !_isAadhaarVerified) ...[
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'Enter Aadhaar OTP',
                                hint: '998877',
                                icon: Icons.lock_clock_outlined,
                                controller: _aadhaarOtpController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                suffix: TextButton(
                                  onPressed: _isLoading ? null : _verifyAadhaar,
                                  child: const Text(
                                    'Verify OTP', 
                                    style: TextStyle(
                                      color: Color(0xFFE65100), 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            
                            if (_isAadhaarVerified) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.verified_user, size: 16, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'Identity Confirmed',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            
                            // Blood Group Dropdown
                            _buildBloodGroupDropdown(),
                            const SizedBox(height: 20),
                            
                            // Address
                            _buildInputField(
                              label: 'Address',
                              hint: 'House no, street, city, pincode',
                              icon: Icons.location_on_outlined,
                              controller: _addressController,
                            ),
                            const SizedBox(height: 32),
                            
                            // Emergency Contacts Section
                            _buildEmergencyContactsSection(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Save & Continue Button
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_isPhoneVerified || !_isAadhaarVerified) 
                          ? null 
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _registerUser();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fix the errors in the form.')),
                                );
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Save & Continue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (!_isPhoneVerified)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Please verify your phone number to continue',
                            style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    
                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shield, size: 16, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                'Protected by Lifeline · ISO 27001 compliant',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: Color(0xFFE65100),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    String aadhaarText = _aadhaarController.text;
    String maskedAadhaar = 'XXXX XXXX ';
    if (aadhaarText.length >= 4) {
      maskedAadhaar += aadhaarText.substring(aadhaarText.length - 4);
    } else {
      maskedAadhaar += 'XXXX';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Profile Created!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your emergency health profile has been securely encrypted and saved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F6F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 18, color: Color(0xFFE65100)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aadhaar (Encrypted)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            maskedAadhaar,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildEmergencyContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Emergency Family Contact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            TextButton.icon(
              onPressed: _addEmergencyContact,
              icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFFE65100)),
              label: const Text(
                'Add More',
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _emergencyContacts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final isPrimary = index == 0;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contact ${index + 1}${isPrimary ? ' • Primary' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      if (!isPrimary)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _emergencyContacts[index]['name']?.dispose();
                              _emergencyContacts[index]['phone']?.dispose();
                              _emergencyContacts.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildNestedInputField(
                    hint: 'Family member name',
                    controller: _emergencyContacts[index]['name'],
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildNestedInputField(
                    hint: '10-digit mobile number',
                    controller: _emergencyContacts[index]['phone'],
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone_android_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildNestedInputField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF9F6F2).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE65100), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }



  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8C42), // Light orange
            Color(0xFFF05F23), // Deep orange
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: Color(0xFFE65100), size: 28),
                      ),
                      const Positioned(
                        child: Icon(Icons.add, color: Colors.white, size: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Lifeline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Emergency Health Profile',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Step 1 of 1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.favorite, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                'Built for the moments that matter most',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: Icon(icon, color: const Color(0xFFE65100)),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF9F6F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            if (label == 'Phone Number' && value.length != 10) {
              return 'Phone number must be exactly 10 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAadhaarField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aadhaar Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isAadhaarVerified ? Colors.green : const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAadhaarVerified ? Icons.verified : Icons.lock, 
                    size: 12, 
                    color: Colors.white
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAadhaarVerified ? 'Verified' : 'Encrypted',
                    style: const TextStyle(
                      fontSize: 10, 
                      color: Colors.white, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          obscureText: !_isAadhaarVerified, // Mask if not verified
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            hintText: 'XXXX XXXX XXXX',
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFE65100)),
            suffixIcon: _isAadhaarVerified 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : TextButton(
                  onPressed: (_isLoading || _isAadhaarOtpSent) ? null : _requestAadhaarOTP,
                  child: Text(
                    _isAadhaarOtpSent ? 'Sent' : 'Verify', 
                    style: TextStyle(
                      color: (_isLoading || _isAadhaarOtpSent) ? Colors.grey : const Color(0xFFE65100), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
            filled: true,
            fillColor: const Color(0xFFF9F6F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Aadhaar Number';
            }
            if (value.length != 12) {
              return 'Aadhaar must be 12 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Blood Group',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBloodGroup,
          hint: const Text('Select blood group', style: TextStyle(color: Colors.black54)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.water_drop, color: Color(0xFFE65100)),
            filled: true,
            fillColor: const Color(0xFFF9F6F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          items: _bloodGroups.map((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedBloodGroup = newValue;
            });
          },
          validator: (value) => value == null ? 'Please select a blood group' : null,
        ),
      ],
    );
  }
}
