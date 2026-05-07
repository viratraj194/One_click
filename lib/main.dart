import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');

  if (token != null) {
    // Sync profile data (especially emergency contact) on app start
    final apiService = ApiService();
    await apiService.getProfile();
  }

  runApp(OneClickApp(initialScreen: token != null ? const DashboardScreen() : const LoginScreen()));
}

class OneClickApp extends StatelessWidget {
  final Widget initialScreen;
  const OneClickApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Click Lifeline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}