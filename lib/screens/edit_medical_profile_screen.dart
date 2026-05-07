import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditMedicalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditMedicalProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditMedicalProfileScreen> createState() => _EditMedicalProfileScreenState();
}

class _EditMedicalProfileScreenState extends State<EditMedicalProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _conditionsController;
  String? _selectedBloodGroup;

  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _allergiesController = TextEditingController(text: widget.profileData['allergies']);
    _medicationsController = TextEditingController(text: widget.profileData['medications']);
    _conditionsController = TextEditingController(text: widget.profileData['conditions']);
    _selectedBloodGroup = widget.profileData['blood_group'];
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      'blood_group': _selectedBloodGroup,
      'allergies': _allergiesController.text.trim(),
      'medications': _medicationsController.text.trim(),
      'conditions': _conditionsController.text.trim(),
    };

    try {
      final result = await _apiService.updateProfile(updatedData);
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medical profile updated!'), backgroundColor: Colors.green),
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
        title: const Text('Medical Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    _buildBloodGroupDropdown(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      icon: Icons.front_hand_outlined,
                      hint: 'e.g. Peanuts, Penicillin',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _medicationsController,
                      label: 'Current Medications',
                      icon: Icons.medication_outlined,
                      hint: 'e.g. Aspirin 100mg',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _conditionsController,
                      label: 'Conditions',
                      icon: Icons.monitor_heart_outlined,
                      hint: 'e.g. Asthma, Diabetes',
                      maxLines: 2,
                    ),
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
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFE65100), size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Blood Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            decoration: const InputDecoration(
              icon: Icon(Icons.bloodtype_outlined, color: Color(0xFFE65100), size: 22),
              border: InputBorder.none,
            ),
            items: _bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
            onChanged: (value) => setState(() => _selectedBloodGroup = value),
          ),
        ),
      ],
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
        ),
        child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
