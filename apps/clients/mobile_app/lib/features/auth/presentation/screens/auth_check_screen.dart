import 'package:flutter/material.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/network/api_client.dart';

import 'login_screen.dart';
import '../../../patients/presentation/screens/student_dashboard_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = StorageService();
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final token = await _storage.read(key: 'accessToken');
    final role = await _storage.read(key: 'userRole');
    final name = await _storage.read(key: 'userName');

    if (token == null || role == null) {
      _goLogin();
      return;
    }

    try {
      final response = await _api.get(
        '/api/v1/patients/profile/status',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboardScreen(
              studentName: name ?? 'Student',
            ),
          ),
          (_) => false,
        );
      } else {
        await _storage.deleteAll();
        _goLogin();
      }
    } catch (_) {
      await _storage.deleteAll();
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
