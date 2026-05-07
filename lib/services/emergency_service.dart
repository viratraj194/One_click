import 'package:geolocator/geolocator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class EmergencyService {
  final ApiService _apiService = ApiService();

  Future<void> triggerTrueOneClickEmergency({
    required List<String> recipients,
    required List<String> selectedServices,
  }) async {
    // 1. Explicitly verify and request SMS and Location permissions
    await [
      Permission.sms,
      Permission.location,
    ].request();

    if (recipients.isEmpty) {
      throw Exception("No emergency contacts provided");
    }

    // 2. Clean recipient phone numbers (remove spaces, hyphens)
    final List<String> cleanRecipients = recipients
        .map((r) => r.replaceAll(RegExp(r'\s+|-'), ''))
        .toList();

    String serviceList = selectedServices.join(", ");
    String message = "EMERGENCY SOS! I need help from: $serviceList.";
    
    try {
      // 3. Get GPS Location
      try {
        Position position = await _determinePosition().timeout(const Duration(seconds: 10));
        String mapsLink = "http://maps.google.com/q=${position.latitude},${position.longitude}";
        message = "EMERGENCY SOS! I need help from: $serviceList. My location: $mapsLink";

        // 4. Trigger Backend SOS
        await _apiService.triggerSOS(
          latitude: position.latitude,
          longitude: position.longitude,
        ).catchError((e) {
          print("Backend SOS Error: $e");
          return {'success': false, 'message': e.toString()};
        });
      } catch (e) {
        print("Location/Backend Error (Continuing with SMS/Call): $e");
        message += " (Location unavailable)";
      }

      // 5. Send Background SMS to all contacts (Awaited sequentially)
      await _sendBackgroundSMS(message, cleanRecipients);

      // 6. Direct Call (Bypass dialer) to the primary contact
      // Placed at the absolute end to avoid interrupting SMS stream
      if (cleanRecipients.isNotEmpty) {
        await _makeDirectCall(cleanRecipients.first);
      }

    } catch (e) {
      print("Emergency Service Critical Error: $e");
      rethrow;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _sendBackgroundSMS(String message, List<String> recipients) async {
    try {
      String _result = await sendSMS(
        message: message,
        recipients: recipients,
      );
      print("SMS Result: $_result");
      // Short delay to ensure SMS dispatch completely before the call starts
      await Future.delayed(const Duration(seconds: 1));
    } catch (error) {
      print("SMS Error: $error");
    }
  }

  Future<void> _makeDirectCall(String number) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(number);
    } catch (e) {
      print("Direct Call Error: $e");
    }
  }
}
