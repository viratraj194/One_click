import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/emergency_service.dart';
import 'profile_screen.dart';
import 'sos_activation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final EmergencyService _emergencyService = EmergencyService();
  final Set<int> _selectedServices = {};
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;
  bool _isEmergencyActivating = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoadingProfile = true);
    final result = await _apiService.getProfile();
    if (result['success']) {
      setState(() {
        _profileData = result['data'];
        _isLoadingProfile = false;
      });
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  final List<Map<String, dynamic>> _services = [
    {
      'id': 0,
      'name': 'Police',
      'number': '112',
      'icon': Icons.local_police_outlined,
      'color': Colors.blue,
    },
    {
      'id': 1,
      'name': 'Ambulance',
      'number': '108',
      'icon': Icons.medical_services_outlined,
      'color': Colors.red,
    },
    {
      'id': 2,
      'name': 'Fire',
      'number': '101',
      'icon': Icons.local_fire_department_outlined,
      'color': Colors.orange,
    },
    {
      'id': 3,
      'name': 'Medical',
      'number': 'Emergency',
      'icon': Icons.health_and_safety_outlined,
      'color': Colors.purple,
    },
  ];

  void _toggleService(int id) {
    setState(() {
      if (_selectedServices.contains(id)) {
        _selectedServices.remove(id);
      } else {
        _selectedServices.add(id);
      }
    });
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 10) return phone ?? '';
    return '${phone.substring(0, 3)} ${phone.substring(3, 5)}***** ${phone.substring(phone.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _profileData?['full_name'] ?? 'User';
    final firstName = fullName.split(' ')[0];
    final bloodGroup = _profileData?['blood_group'] ?? 'N/A';
    final phone = _profileData?['phone_number'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ONE-TOUCH SOS',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ProfileScreen(initialProfileData: _profileData),
                ),
              );
              if (result == true) {
                _fetchProfile();
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Emergency Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        final isSelected = _selectedServices.contains(service['id']);
                        return _buildServiceCard(service, isSelected);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildAlertsSummary(),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'TAP TO ACTIVATE',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSOSButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String firstName, String fullName, String bloodGroup, String? phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Welcome Back, ', style: TextStyle(fontSize: 24, color: Color(0xFF555555))),
            Text(firstName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white54, size: 14),
                  const SizedBox(width: 8),
                  Text(_maskPhone(phone), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.bloodtype, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text('BG: $bloodGroup', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalProfile() {
    final allergies = _profileData?['allergies'] ?? 'None';
    final medications = _profileData?['medications'] ?? 'None';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medical Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMedicalItem('Allergies', allergies),
          const SizedBox(height: 8),
          _buildMedicalItem('Medications', medications),
        ],
      ),
    );
  }

  Widget _buildMedicalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    final contactsRaw = (_profileData?['emergency_contacts'] as List?) ?? [];
    final primaryPhone = _profileData?['emergency_contact_phone']?.toString().replaceAll(RegExp(r'\s+|-'), '');

    // Synchronization Logic: EXCLUDE primary guardian from this secondary list
    List<dynamic> secondaryContacts = List.from(contactsRaw);
    if (primaryPhone != null) {
      secondaryContacts.removeWhere((c) => 
        c['phone_number'].toString().replaceAll(RegExp(r'\s+|-'), '') == primaryPhone);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Emergency Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (secondaryContacts.isEmpty) const Text('No alternative contacts added.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ...secondaryContacts.map((contact) {
            final name = contact['contact_name'] ?? 'Unknown';
            String relation = contact['relationship'] ?? 'Family';
            if (relation.toLowerCase() == 'primary') relation = 'Secondary';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 12),
                  Text('$name - $relation', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleService(service['id']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              service['icon'],
              color: service['color'],
              size: 36,
            ),
            const SizedBox(height: 6),
            Text(
              service['name'],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: service['color'],
              ),
            ),
            Text(
              service['number'],
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Alerts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selected services will be notified',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE65100),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${_selectedServices.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: _isEmergencyActivating ? Colors.grey : const Color(0xFFE65100),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (_isEmergencyActivating ? Colors.grey : const Color(0xFFE65100)).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEmergencyActivating
              ? null
              : () {
                  if (_selectedServices.isNotEmpty) {
                    _triggerEmergencyHelp();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one service first!')),
                    );
                  }
                },
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEmergencyActivating)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                const Text(
                  'HELP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerEmergencyHelp() async {
    setState(() => _isEmergencyActivating = true);
    try {
      // 1. Compile selected services
      final selectedServiceNames = _services
          .where((s) => _selectedServices.contains(s['id']))
          .map((s) => s['name'] as String)
          .toList();

      // 2. Gather all emergency contact numbers
      final List<String> recipients = [];
      
      // Add primary emergency phone if it exists
      final primaryPhone = _profileData?['emergency_contact_phone'];
      if (primaryPhone != null && primaryPhone.toString().isNotEmpty) {
        recipients.add(primaryPhone.toString());
      }

      // Add other contacts from the emergency_contacts list
      final otherContacts = (_profileData?['emergency_contacts'] as List?) ?? [];
      for (var contact in otherContacts) {
        final phone = contact['phone_number'];
        if (phone != null && phone.toString().isNotEmpty && !recipients.contains(phone.toString())) {
          recipients.add(phone.toString());
        }
      }

      if (recipients.isEmpty) {
        throw Exception("Please add at least one emergency contact in your profile first.");
      }
      
      // 3. Trigger True One-Click Emergency Service
      await _emergencyService.triggerTrueOneClickEmergency(
        recipients: recipients,
        selectedServices: selectedServiceNames,
      );

      if (mounted) {
        _showSOSActivationDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEmergencyActivating = false);
      }
    }
  }

  void _showSOSActivationDialog() {
    final activeServices = _services.where((s) => _selectedServices.contains(s['id'])).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SOSActivationScreen(selectedServices: activeServices),
      ),
    ).then((_) {
      setState(() {
        _selectedServices.clear();
      });
    });
  }
}
