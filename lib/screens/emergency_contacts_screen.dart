import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContactControllers {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController relationController;

  ContactControllers({
    String name = '',
    String phone = '',
    String relation = '',
  })  : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone),
        relationController = TextEditingController(text: relation);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();
  }
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  final List<ContactControllers> _contacts = [];
  final int _maxContacts = 5;

  @override
  void initState() {
    super.initState();
    _fetchExistingContacts();
  }

  @override
  void dispose() {
    for (var contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchExistingContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.getProfile();
      if (result['success']) {
        final existingContacts = result['data']['emergency_contacts'] as List?;
        setState(() {
          _contacts.clear();
          if (existingContacts != null && existingContacts.isNotEmpty) {
            for (var contactData in existingContacts) {
              _contacts.add(ContactControllers(
                name: contactData['contact_name'] ?? '',
                phone: contactData['phone_number'] ?? '',
                relation: contactData['relationship'] ?? '',
              ));
            }
          } else {
            // Add at least one empty contact if none exist
            _contacts.add(ContactControllers());
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load existing contacts')),
        );
      }
      // Fallback: Ensure at least one contact slot if load fails
      if (_contacts.isEmpty) {
        setState(() {
          _contacts.add(ContactControllers());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addContact() {
    if (_contacts.length < _maxContacts) {
      setState(() {
        _contacts.add(ContactControllers());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $_maxContacts contacts.')),
      );
    }
  }

  void _removeContact(int index) {
    if (_contacts.length > 1) {
      setState(() {
        _contacts[index].dispose();
        _contacts.removeAt(index);
      });
    }
  }

  Future<void> _saveContacts() async {
    setState(() {
      _isSaving = true;
    });

    List<Map<String, String>> contactsToSync = [];
    for (var contact in _contacts) {
      if (contact.nameController.text.isNotEmpty && contact.phoneController.text.isNotEmpty) {
        contactsToSync.add({
          'contact_name': contact.nameController.text,
          'phone_number': contact.phoneController.text,
          'relationship': contact.relationController.text,
        });
      }
    }

    print('DEBUG: Sending Contacts to Server: ${jsonEncode(contactsToSync)}');

    try {
      final result = await _apiService.syncContacts(contactsToSync);
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lifelines Updated Successfully')),
          );
          Navigator.of(context).pop(true); // Return true to trigger refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to update contacts')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Lifelines',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add up to $_maxContacts trusted contacts who will be notified in case of an emergency.',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _contacts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) => _buildContactSlot(index),
                    ),
                    if (_contacts.length < _maxContacts) ...[
                      const SizedBox(height: 24),
                      _buildAddButton(),
                    ],
                    const SizedBox(height: 48),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactSlot(int index) {
    final contact = _contacts[index];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE65100),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (index > 0)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removeContact(index),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: contact.nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: contact.phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hintText: '+91 98765 43210',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: contact.relationController,
            label: 'Relationship (e.g. Father, Friend)',
            icon: Icons.family_restroom_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFFE65100), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9F6F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addContact,
        icon: const Icon(Icons.add, color: Color(0xFFE65100)),
        label: const Text(
          'Add Another Contact',
          style: TextStyle(
            color: Color(0xFFE65100),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE65100), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveContacts,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Save Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
