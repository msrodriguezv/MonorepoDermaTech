import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../patients/data/datasources/patient_remote_data_source.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = StorageService();

  static const Color _brandColor = Color(0xFF0A2342);

  @override
  void initState() {
    super.initState();
    _initializeSessionCheck();
  }

  Future<void> _initializeSessionCheck() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    try {
      final String? accessToken = await _storage.read(key: 'accessToken');
      final String? userRole = await _storage.read(key: 'userRole');

      if (accessToken != null && accessToken.isNotEmpty && userRole != null) {
        await _decideNavigationAndRedirect(userRole);
      } else {
        _navigateToLogin();
      }
    } catch (error) {
      _navigateToLogin();
    }
  }

  Future<void> _decideNavigationAndRedirect(String role) async {
    final String normalizedRole = role.toUpperCase().trim();

    if (normalizedRole == 'STUDENT' || normalizedRole == 'PATIENT') {
      await _handleStudentFlow();
    } else if (normalizedRole.contains('DOCTOR') || normalizedRole.contains('MEDICO')) {
      context.go('/doctor');
    } else if (normalizedRole.contains('NURSE') || normalizedRole.contains('ENFERMERO')) {
      context.go('/nurse');
    } else if (normalizedRole.contains('ADMIN')) {
      context.go('/admin');
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _handleStudentFlow() async {
    try {
      final apiClient = ApiClient();
      final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
      final status = await patientDataSource.getProfileStatus();

      if (!mounted) return;

      if (status.isProfileComplete) {
        context.go('/profile');
      } else {
        final savedEmail = await _storage.read(key: 'userEmail');
        context.go('/profile/complete', extra: savedEmail ?? '');
      }
    } catch (e) {
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_rounded, size: 90, color: _brandColor),
            SizedBox(height: 24),
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
            ),
            SizedBox(height: 20),
            Text(
              "Iniciando sesión...",
              style: TextStyle(
                color: _brandColor, 
                fontSize: 16, 
                fontWeight: FontWeight.w500
              ),
            )
          ],
        ),
      ),
    );
  }
}