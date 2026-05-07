import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_secondary_contact_screen.dart';

class EditContactsScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;

  const EditContactsScreen({
    Key? key,
    required this.currentName,
    required this.currentPhone,
  }) : super(key: key);

  @override
  State<EditContactsScreen> createState() => _EditContactsScreenState();
}

class _EditContactsScreenState extends State<EditContactsScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _primaryNameController;
  late TextEditingController _primaryPhoneController;
  
  // Secondary contacts state
  List<Map<String, String>> _secondaryContacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _primaryNameController = TextEditingController(
      text: widget.currentName == 'Not Set' ? '' : widget.currentName,
    );
    
    // Enforce 10-digit display by stripping +91 if present
    String cleanPhone = widget.currentPhone.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanPhone.startsWith('+91')) {
      cleanPhone = cleanPhone.substring(3);
    }
    _primaryPhoneController = TextEditingController(text: cleanPhone);
    
    _fetchSecondaryContacts();
  }

  Future<void> _fetchSecondaryContacts() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getProfile();
    if (result['success']) {
      final List rawContacts = result['data']['emergency_contacts'] ?? [];
      final primaryPhone = widget.currentPhone.replaceAll(RegExp(r'\s+|-'), '');
      
      setState(() {
        _secondaryContacts = rawContacts
            .where((c) => c['phone_number'].toString().replaceAll(RegExp(r'\s+|-'), '') != primaryPhone)
            .map<Map<String, String>>((c) => {
                  'contact_name': c['contact_name'].toString(),
                  'relationship': c['relationship'].toString(),
                  'phone_number': c['phone_number'].toString(),
                })
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _primaryNameController.dispose();
    _primaryPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAllChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Automatically combine +91 with the 10-digit input
    final fullPrimaryPhone = "+91${_primaryPhoneController.text.trim()}";

    // 1. Update Primary Guardian
    final primaryUpdate = await _apiService.updateProfile({
      'emergency_contact_name': _primaryNameController.text.trim(),
      'emergency_contact_phone': fullPrimaryPhone,
    });

    if (!primaryUpdate['success']) {
      _showError(primaryUpdate['message'] ?? 'Failed to update primary contact');
      setState(() => _isLoading = false);
      return;
    }

    // 2. Sync Secondary Contacts
    final secondarySync = await _apiService.syncContacts(_secondaryContacts);

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (secondarySync['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All guardian details updated'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      _showError(secondarySync['message'] ?? 'Failed to sync secondary contacts');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _addNewSecondaryContact() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSecondaryContactScreen(
          primaryPhone: "+91${_primaryPhoneController.text.trim()}",
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _secondaryContacts.add(result);
      });
    }
  }

  void _editSecondaryContact(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSecondaryContactScreen(
          initialContact: _secondaryContacts[index],
          primaryPhone: "+91${_primaryPhoneController.text.trim()}",
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _secondaryContacts[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Guardians', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    _buildSectionHeader('Primary Guardian', 'This is your main emergency contact.'),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _primaryNameController,
                      label: 'Full Name',
                      icon: Icons.person_pin_outlined,
                      validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _primaryPhoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      isPhone: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Phone required';
                        if (v.length != 10) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildSectionHeader('Alternative Guardians', 'Additional contacts alerted during SOS.'),
                    const SizedBox(height: 16),
                    ..._secondaryContacts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final contact = entry.value;
                      return _buildSecondaryContactTile(contact, idx);
                    }).toList(),
                    const SizedBox(height: 12),
                    _buildAddSecondaryButton(),
                    const SizedBox(height: 60),
                    _buildSaveAllButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildSecondaryContactTile(Map<String, String> contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE65100).withOpacity(0.1),
            child: const Icon(Icons.people, color: Color(0xFFE65100), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['contact_name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${contact['relationship']} • ${contact['phone_number']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            onPressed: () => _editSecondaryContact(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: () => setState(() => _secondaryContacts.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSecondaryButton() {
    return OutlinedButton.icon(
      onPressed: _addNewSecondaryContact,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Add Secondary Guardian'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE65100),
        side: const BorderSide(color: Color(0xFFE65100)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE65100), size: 22),
        prefixText: isPhone ? '+91 ' : null,
        prefixStyle: isPhone ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black) : null,
        hintText: isPhone ? '7070342402' : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: validator,
    );
  }

  Widget _buildSaveAllButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveAllChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: const Text('Confirm All Guardians', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
