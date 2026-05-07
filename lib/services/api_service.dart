import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://127.0.0.1:8000/api/';
  static const String baseUrl = 'http://192.168.0.105:8000/api/';

  Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  void _logError(http.Response response) {
    print('status_code: ${response.statusCode}');
    // Stopped printing body to avoid HTML dumps as requested
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    required String bloodGroup,
    required String aadhaar,
  }) async {
    final url = Uri.parse('${baseUrl}accounts/register/');
    
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'blood_group': bloodGroup,
          'aadhaar': aadhaar,
        }),
      );

      if (response.statusCode != 201) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        String errorMessage = 'Registration failed.';
        if (responseData is Map && responseData.isNotEmpty) {
          errorMessage = responseData.values.first is List 
              ? responseData.values.first[0].toString() 
              : responseData.values.first.toString();
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to the server.',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${baseUrl}accounts/login/');
    
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store emergency contact phone if present
        if (responseData['user'] != null && responseData['user']['emergency_contact_phone'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('emergency_contact_phone', responseData['user']['emergency_contact_phone']);
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to the server.',
      };
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final url = Uri.parse('${baseUrl}accounts/profile/');
    
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store emergency contact phone if present
        if (responseData['emergency_contact_phone'] != null) {
          await prefs.setString('emergency_contact_phone', responseData['emergency_contact_phone']);
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to fetch profile.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to the server.',
      };
    }
  }

  Future<Map<String, dynamic>> triggerSOS({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final url = Uri.parse('${baseUrl}emergency/sos-trigger/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 201) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to trigger SOS.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final url = Uri.parse('${baseUrl}accounts/profile/');
    
    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        String errorMessage = 'Update failed.';
        if (responseData is Map && responseData.isNotEmpty) {
          errorMessage = responseData.values.first is List 
              ? responseData.values.first[0].toString() 
              : responseData.values.first.toString();
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to the server.',
      };
    }
  }

  Future<Map<String, dynamic>> syncContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final url = Uri.parse('${baseUrl}accounts/contacts/');
    
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(contacts),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        _logError(response);
      }
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        String errorMessage = 'Failed to sync contacts.';
        if (responseData is List && responseData.isNotEmpty) {
          final firstError = responseData[0];
          if (firstError is Map && firstError.isNotEmpty) {
            errorMessage = firstError.values.first is List 
                ? firstError.values.first[0].toString() 
                : firstError.values.first.toString();
          }
        } else if (responseData is Map && responseData.isNotEmpty) {
          errorMessage = responseData.values.first is List 
              ? responseData.values.first[0].toString() 
              : responseData.values.first.toString();
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to the server.',
      };
    }
  }

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    final url = Uri.parse('${baseUrl}accounts/send-otp/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to send OTP.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
    final url = Uri.parse('${baseUrl}accounts/verify-phone/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Invalid OTP.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> requestAadhaarOTP(String aadhaar) async {
    final url = Uri.parse('${baseUrl}accounts/aadhaar-otp/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'aadhaar': aadhaar}),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message'], 'otp': responseData['otp']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to send Aadhaar OTP.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> verifyAadhaar(String aadhaar, String otp, {String? phone}) async {
    final url = Uri.parse('${baseUrl}accounts/aadhaar-verify/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'aadhaar': aadhaar,
          'otp': otp,
          'phone': phone,
        }),
      );

      if (response.statusCode != 200) {
        _logError(response);
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Invalid Aadhaar OTP.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }
}

