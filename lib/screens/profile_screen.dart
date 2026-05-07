import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:one_click/services/api_service.dart';
import 'package:one_click/screens/edit_profile_screen.dart';
import 'package:one_click/screens/edit_medical_profile_screen.dart';
import 'package:one_click/screens/edit_contacts_screen.dart';
import 'package:one_click/screens/registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfileData;

  const ProfileScreen({Key? key, this.initialProfileData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  // State Initialization
  String _userName = 'User';
  String _userPhone = '';
  String _bloodGroup = 'N/A';
  String _aadhaarNum = '';

  // Preference Hooks
  String _selectedSosType = 'Both';
  bool _isSilentMode = false;
  bool _shouldShareLocation = true;

  @override
  void initState() {
    super.initState();
    // If initial data is provided, parse it immediately to avoid loading state
    if (widget.initialProfileData != null) {
      _profileData = widget.initialProfileData;
      _parseProfileData(_profileData!);
      _isLoading = false;
    }

    // Delay the network fetch until after the transition finishes for smooth navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _fetchProfileData();
      });
    });
  }

  void _parseProfileData(Map<String, dynamic> data) {
    _userName = data['name'] ?? data['full_name'] ?? 'User';
    _userPhone = data['phone'] ?? data['phone_number'] ?? '';
    _bloodGroup = data['blood_group'] ?? 'N/A';
    _aadhaarNum = data['aadhaar_number'] ?? '';
    
    _selectedSosType = data['sos_type'] ?? 'Both';
    _isSilentMode = data['silent_mode'] ?? false;
    _shouldShareLocation = data['share_location'] ?? true;
  }

  // API Connection
  Future<void> _fetchProfileData() async {
    // Only show loading if we don't already have data
    if (_profileData == null) {
      setState(() => _isLoading = true);
    }
    
    final result = await _apiService.getProfile();
    if (result['success'] && mounted) {
      setState(() {
        _profileData = result['data'];
        _parseProfileData(_profileData!);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    // Local state update inside setState block
    setState(() {
      if (key == 'sos_type') _selectedSosType = value;
      if (key == 'silent_mode') _isSilentMode = value;
      if (key == 'share_location') _shouldShareLocation = value;
    });

    // Backend Network Hook: Asynchronous HTTP PATCH request
    final result = await _apiService.updateProfile({key: value});
    
    if (!result['success']) {
      // Revert local state if update fails
      _fetchProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } else {
      setState(() {
        _profileData?[key] = value;
      });
    }
  }

  void _navigateToEditPersonalDetails() async {
    if (_profileData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(profileData: _profileData!)),
    );
    if (result == true) _fetchProfileData();
  }

  void _navigateToEditMedicalProfile() async {
    if (_profileData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditMedicalProfileScreen(profileData: _profileData!)),
    );
    if (result == true) _fetchProfileData();
  }

  void _navigateToEditContacts() async {
    if (_profileData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactsScreen(
          currentName: _profileData!['emergency_contact_name'] ?? 'Not Set',
          currentPhone: _profileData!['emergency_contact_phone'] ?? 'Not Set',
        ),
      ),
    );
    if (result == true) _fetchProfileData();
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
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UI Binding
                  _ProfileHeader(
                    userName: _userName,
                    userPhone: _userPhone,
                    bloodGroup: _bloodGroup,
                    aadhaarNum: _aadhaarNum,
                    onEdit: _navigateToEditPersonalDetails,
                  ),
                  const SizedBox(height: 24),
                  _PrimaryContactCard(
                    profileData: _profileData,
                    onEdit: _navigateToEditContacts,
                  ),
                  const SizedBox(height: 24),
                  _EmergencyContactsSection(
                    profileData: _profileData,
                    onEdit: _navigateToEditContacts,
                  ),
                  const SizedBox(height: 24),
                  _MedicalProfileSection(
                    profileData: _profileData,
                    onEdit: _navigateToEditMedicalProfile,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Emergency Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDefaultSOSTile(),
                  const SizedBox(height: 16),
                  _buildSilentModeTile(),
                  const SizedBox(height: 16),
                  _buildShareLocationTile(),
                  const SizedBox(height: 48),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Logout from Lifeline',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDefaultSOSTile() {
    final displayValue = _selectedSosType == 'Both' ? 'Police & Ambulance' : _selectedSosType;

    return _buildCard(
      child: ListTile(
        leading: const Icon(Icons.sos, color: Color(0xFFE65100), size: 28),
        title: const Text('Default SOS', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(displayValue, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        onTap: () => _showSOSPreferenceModal(),
      ),
    );
  }

  Widget _buildSilentModeTile() {
    return _buildCard(
      child: ListTile(
        leading: Icon(
          _isSilentMode ? Icons.volume_off : Icons.volume_up,
          color: _isSilentMode ? Colors.orange : const Color(0xFFE65100),
          size: 28,
        ),
        title: const Text('Silent Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_isSilentMode ? 'On' : 'Off', style: TextStyle(color: Colors.grey[600])),
        trailing: Switch(
          value: _isSilentMode,
          onChanged: (value) => _updatePreference('silent_mode', value),
          activeColor: Colors.orange,
        ),
        onTap: () => _updatePreference('silent_mode', !_isSilentMode),
      ),
    );
  }

  Widget _buildShareLocationTile() {
    return _buildCard(
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: _shouldShareLocation ? const Color(0xFFE65100) : Colors.grey,
          size: 28,
        ),
        title: const Text('Share Location', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_shouldShareLocation ? 'Enabled' : 'Disabled', style: TextStyle(color: Colors.grey[600])),
        trailing: Switch(
          value: _shouldShareLocation,
          onChanged: (value) => _updatePreference('share_location', value),
          activeColor: const Color(0xFFE65100),
        ),
        onTap: () => _updatePreference('share_location', !_shouldShareLocation),
      ),
    );
  }


  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  void _showSOSPreferenceModal() {
    final currentType = _selectedSosType;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Default SOS Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildOption('Police', Icons.local_police_outlined, currentType),
              _buildOption('Ambulance', Icons.medical_services_outlined, currentType),
              _buildOption('Both', Icons.all_inclusive, currentType, label: 'Police & Ambulance'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(String value, IconData icon, String currentType, {String? label}) {
    final isSelected = currentType == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFE65100) : Colors.grey),
      title: Text(
        label ?? value,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFFE65100) : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE65100)) : null,
      onTap: () {
        _updatePreference('sos_type', value);
        Navigator.pop(context);
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userPhone;
  final String bloodGroup;
  final String aadhaarNum;
  final VoidCallback onEdit;

  _ProfileHeader({
    required this.userName,
    required this.userPhone,
    required this.bloodGroup,
    required this.aadhaarNum,
    required this.onEdit,
  });

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 10) return phone ?? '';
    return '${phone.substring(0, 3)} ${phone.substring(3, 5)}***** ${phone.substring(phone.length - 3)}';
  }

  String _maskAadhaar(String? aadhaar) {
    if (aadhaar == null || aadhaar.length < 12) return aadhaar ?? '';
    return '**** **** ${aadhaar.substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ')[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Welcome Back, ', style: TextStyle(fontSize: 24, color: Color(0xFF555555))),
            Text(firstName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF4CAF50), size: 14),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.phone, text: _maskPhone(userPhone)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _InfoRow(icon: Icons.bloodtype, text: 'Blood Group: $bloodGroup')),
                  const SizedBox(width: 12),
                  Expanded(child: _InfoRow(icon: Icons.badge, text: 'Aadhaar: ${_maskAadhaar(aadhaarNum)}')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _EmergencyContactsSection extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onEdit;

  const _EmergencyContactsSection({required this.profileData, required this.onEdit});

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    // Format: +91 70*****485
    String clean = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.length >= 10) {
      String prefix = clean.startsWith('+91') ? '+91 ' : '';
      String digits = clean.startsWith('+91') ? clean.substring(3) : clean;
      if (digits.length >= 10) {
        return '$prefix${digits.substring(0, 2)}*****${digits.substring(digits.length - 3)}';
      }
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final contactsRaw = (profileData?['emergency_contacts'] as List?) ?? [];
    final primaryPhone = profileData?['emergency_contact_phone']?.toString().replaceAll(RegExp(r'\s+|-'), '');

    // Synchronization Logic: EXCLUDE primary guardian from this secondary list
    List<dynamic> secondaryContacts = List.from(contactsRaw);
    if (primaryPhone != null) {
      secondaryContacts.removeWhere((c) => 
        c['phone_number'].toString().replaceAll(RegExp(r'\s+|-'), '') == primaryPhone);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_outline, color: Color(0xFFE65100), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alternative Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('Secondary guardians notified during SOS', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (secondaryContacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text('No alternative contacts added.', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: secondaryContacts.length,
              itemBuilder: (context, index) {
                final contact = secondaryContacts[index];
                final name = contact['contact_name'] ?? 'Unknown';
                String relation = contact['relationship'] ?? 'Alternative';
                if (relation.toLowerCase() == 'primary') relation = 'Secondary Guardian';
                
                final phone = contact['phone_number'] ?? '';
                final initials = name.isNotEmpty ? name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase() : '?';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('$relation • ${_maskPhone(phone)}', 
                              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call_outlined, color: Color(0xFFE65100), size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100).withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Divider(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Manage All Guardians', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalProfileSection extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onEdit;

  const _MedicalProfileSection({required this.profileData, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final allergies = profileData?['allergies'] ?? 'None';
    final medications = profileData?['medications'] ?? 'None';
    final conditions = profileData?['conditions'] ?? 'None';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services_outlined, color: Color(0xFFE65100), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medical Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('Last updated 2 weeks ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MedicalItemRow(
            icon: Icons.front_hand_outlined,
            label: 'Allergies',
            value: allergies,
          ),
          const Divider(height: 24),
          _MedicalItemRow(
            icon: Icons.medication_outlined,
            label: 'Current Medications',
            value: medications,
          ),
          const Divider(height: 24),
          _MedicalItemRow(
            icon: Icons.monitor_heart_outlined,
            label: 'Conditions',
            value: conditions,
          ),
          const Divider(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Medical Info', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MedicalItemRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE65100), size: 20),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PrimaryContactCard extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onEdit;

  const _PrimaryContactCard({required this.profileData, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = profileData?['emergency_contact_name'] ?? 'Not Set';
    final phone = profileData?['emergency_contact_phone'] ?? 'Not Set';

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE65100).withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE65100).withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Primary Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const Icon(Icons.edit, color: Color(0xFFE65100), size: 18),
              ],
            ),
            const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0xFFE65100), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
