import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:one_click/services/api_service.dart';
import 'package:one_click/screens/registration_screen.dart';
import 'package:one_click/screens/edit_profile_screen.dart';
import 'package:one_click/screens/edit_medical_profile_screen.dart';
import 'package:one_click/screens/edit_contacts_screen.dart';
import 'package:one_click/screens/emergency_contacts_screen.dart';

class ProfileDashboard extends StatefulWidget {
  const ProfileDashboard({Key? key}) : super(key: key);

  @override
  State<ProfileDashboard> createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends State<ProfileDashboard> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getProfile();
      if (result['success']) {
        setState(() {
          _profileData = result['data'];
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditPersonalDetails() async {
    if (_profileData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(profileData: _profileData!)),
    );
    if (result == true) _fetchProfile();
  }

  void _navigateToEditMedicalProfile() async {
    if (_profileData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditMedicalProfileScreen(profileData: _profileData!)),
    );
    if (result == true) _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.shield_outlined, color: Colors.black),
        title: Column(
          children: [
            const Text(
              'LIFELINE',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
            ),
            Text(
              'User Profile',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: RepaintBoundary(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _ProfileContent(
                    profileData: _profileData,
                    onEditProfile: _navigateToEditPersonalDetails,
                    onEditPrimaryContact: () async {
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
                      if (result == true) {
                        _fetchProfile();
                      }
                    },
                    onUpdateSOS: (String type) async {
                      final result = await _apiService.updateProfile({'sos_type': type});
                      if (result['success']) {
                        _fetchProfile();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'])),
                          );
                        }
                      }
                    },
                    onEditContacts: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                      );
                      if (result == true) {
                        _fetchProfile();
                      }
                    },
                    onLogout: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('auth_token');
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                          (route) => false,
                        );
                      }
                    },
                    onEditMedical: _navigateToEditMedicalProfile,
                  ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPrimaryContact;
  final Function(String) onUpdateSOS;
  final VoidCallback onEditContacts;
  final VoidCallback onLogout;
  final VoidCallback onEditMedical;

  const _ProfileContent({
    required this.profileData,
    required this.onEditProfile,
    required this.onEditPrimaryContact,
    required this.onUpdateSOS,
    required this.onEditContacts,
    required this.onLogout,
    required this.onEditMedical,
  });

  @override
  Widget build(BuildContext context) {
    final sosType = profileData?['sos_type'] ?? 'Both';
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _ProfileHeader(profileData: profileData, onEdit: onEditProfile),
            const SizedBox(height: 24),
            _StatsRow(profileData: profileData),
            const SizedBox(height: 24),
            _PrimaryContactCard(profileData: profileData, onEdit: onEditPrimaryContact),
            const SizedBox(height: 20),
            _EmergencyContactsSection(profileData: profileData, onEdit: onEditContacts),
            const SizedBox(height: 20),
            _MedicalProfileSection(profileData: profileData, onEdit: onEditMedical),
            const SizedBox(height: 20),
            _PreferencesSection(sosType: sosType, onUpdateSOS: onUpdateSOS),
            const SizedBox(height: 40),
            const _ProfileFooter(),
            const SizedBox(height: 32),
            _LogoutButton(onLogout: onLogout),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.profileData, required this.onEdit});

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
    final fullName = profileData?['full_name'] ?? 'User';
    final firstName = fullName.split(' ')[0];
    final phone = profileData?['phone_number'];
    final bloodGroup = profileData?['blood_group'] ?? 'N/A';
    final aadhaar = profileData?['aadhaar_number'];
    final initials = fullName.isNotEmpty 
        ? fullName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase() 
        : 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Hello, ', style: const TextStyle(fontSize: 28, color: Colors.black)),
            Text(firstName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE65100), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your lifeline profile is active and ready for emergencies.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('Active • ID verified', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoBlock(label: 'PHONE', value: _maskPhone(phone)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _InfoBlock(label: 'BLOOD GROUP', value: bloodGroup)),
                  const SizedBox(width: 12),
                  Expanded(child: _InfoBlock(label: 'AADHAAR', value: _maskAadhaar(aadhaar))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const _StatsRow({required this.profileData});

  @override
  Widget build(BuildContext context) {
    final contactCount = (profileData?['emergency_contacts'] as List?)?.length ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(value: '$contactCount', label: 'CONTACTS', isOrange: false),
        const _StatItem(value: '100%', label: 'PROFILE'),
        const _StatItem(value: '24/7', label: 'SOS'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isOrange;

  const _StatItem({required this.value, required this.label, this.isOrange = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isOrange ? const Color(0xFFE65100) : Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF555555), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

    return Container(
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
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Color(0xFFE65100), size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
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
    );
  }
}

class _EmergencyContactsSection extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onEdit;

  const _EmergencyContactsSection({required this.profileData, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final contacts = (profileData?['emergency_contacts'] as List?) ?? [];

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
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('These contacts are alerted during SOS', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No emergency contacts added.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...contacts.map((contact) {
              final name = contact['contact_name'] ?? 'Unknown';
              final relation = contact['relationship'] ?? 'Family';
              final phone = contact['phone_number'] ?? '';
              final initials = name.isNotEmpty ? name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase() : '?';

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
                          Text('$relation • ${phone.length > 5 ? phone.replaceRange(2, 7, '*****') : phone}', 
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.call, color: Color(0xFFE65100), size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100).withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          const Divider(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _PreferencesSection extends StatelessWidget {
  final String sosType;
  final Function(String) onUpdateSOS;

  const _PreferencesSection({required this.sosType, required this.onUpdateSOS});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        _PreferencesCard(sosType: sosType, onUpdateSOS: onUpdateSOS),
      ],
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final String sosType;
  final Function(String) onUpdateSOS;

  const _PreferencesCard({required this.sosType, required this.onUpdateSOS});

  String _getDisplayValue(String type) {
    if (type == 'Both') return 'Police & Ambulance';
    return type;
  }

  void _showSOSPreferenceModal(BuildContext context) {
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
              const Text(
                'Default SOS Services',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOption(context, 'Police', Icons.local_police_outlined),
              _buildOption(context, 'Ambulance', Icons.medical_services_outlined),
              _buildOption(context, 'Both', Icons.all_inclusive, label: 'Police & Ambulance'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(BuildContext context, String value, IconData icon, {String? label}) {
    final isSelected = sosType == value;
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
        onUpdateSOS(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _PreferenceItem(
            icon: Icons.sos,
            title: 'Default SOS',
            value: _getDisplayValue(sosType),
            onTap: () => _showSOSPreferenceModal(context),
          ),
          const Divider(height: 1),
          const _PreferenceItem(icon: Icons.volume_off, title: 'Silent Mode', value: 'Off'),
          const Divider(height: 1),
          const _PreferenceItem(icon: Icons.location_on, title: 'Share Location', value: 'Enabled'),
        ],
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _PreferenceItem({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE65100), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, color: Colors.grey, size: 14),
          SizedBox(width: 8),
          Text('Secured by Lifeline • End-to-end encrypted', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Logout from Lifeline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
