import 'package:flutter/material.dart';

class AddSecondaryContactScreen extends StatefulWidget {
  final Map<String, String>? initialContact;
  final String primaryPhone;

  const AddSecondaryContactScreen({
    Key? key,
    this.initialContact,
    required this.primaryPhone,
  }) : super(key: key);

  @override
  State<AddSecondaryContactScreen> createState() => _AddSecondaryContactScreenState();
}

class _AddSecondaryContactScreenState extends State<AddSecondaryContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _relController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialContact?['contact_name'] ?? '');
    _relController = TextEditingController(text: widget.initialContact?['relationship'] ?? '');
    
    // Enforce 10-digit display by stripping +91 if present
    String phoneText = widget.initialContact?['phone_number'] ?? '';
    String cleanPhone = phoneText.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanPhone.startsWith('+91')) {
      cleanPhone = cleanPhone.substring(3);
    }
    _phoneController = TextEditingController(text: cleanPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final contact = {
        'contact_name': _nameController.text.trim(),
        'relationship': _relController.text.trim(),
        // Combine +91 with the 10-digit input before saving
        'phone_number': "+91${_phoneController.text.trim()}",
      };
      Navigator.pop(context, contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialContact != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Alternate Contact' : 'Add Alternate Contact',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guardian Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please provide the details for your secondary emergency contact.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_pin_outlined,
                      validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _relController,
                      label: 'Relationship (e.g. Sibling, Friend)',
                      icon: Icons.family_restroom_outlined,
                      validator: (v) => (v == null || v.isEmpty) ? 'Relationship is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      isPhone: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Phone number is required';
                        if (v.length != 10) return 'Enter a valid 10-digit number';
                        
                        // Combine with +91 to check against primary guardian
                        final fullPhone = "+91${v.trim()}";
                        if (fullPhone.replaceAll(RegExp(r'\s+|-'), '') == widget.primaryPhone.replaceAll(RegExp(r'\s+|-'), '')) {
                          return 'This contact is already configured as your primary guardian.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Update Contact' : 'Save Contact',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPhone = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFE65100), size: 22),
        prefixText: isPhone ? '+91 ' : null,
        prefixStyle: isPhone ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black) : null,
        hintText: isPhone ? 'Enter 10-digit mobile number' : null,
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        floatingLabelStyle: const TextStyle(color: Color(0xFFE65100)),
      ),
      validator: validator,
    );
  }
}
