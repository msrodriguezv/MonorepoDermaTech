import 'package:flutter/material.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../patients/data/datasources/patient_remote_data_source.dart';
import 'login_screen.dart';
import '../../../patients/presentation/screens/student_dashboard_screen.dart';
import '../../../patients/presentation/screens/complete_profile_screen.dart';
import '../../../doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../nurse/presentation/screens/nurse_dashboard_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _initializeSessionCheck();
  }

  Future<void> _initializeSessionCheck() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final String? accessToken = await _storage.read(key: 'accessToken');
      final String? userRole = await _storage.read(key: 'userRole');

      if (accessToken != null && accessToken.isNotEmpty && userRole != null) {
        if (!mounted) return;
        await _decideNavigationAndRedirect(userRole);
      } else {
        if (!mounted) return;
        _navigateToLogin();
      }
    } catch (error) {
      if (mounted) _navigateToLogin();
    }
  }

  Future<void> _decideNavigationAndRedirect(String role) async {
    final String normalizedRole = role.toUpperCase().trim();
    Widget targetScreen;

    if (normalizedRole == 'STUDENT' || normalizedRole == 'PATIENT') {
      try {
        final apiClient = ApiClient();
        final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
        final status = await patientDataSource.getProfileStatus();

        if (status.isProfileComplete) {
          targetScreen = const StudentDashboardScreen();
        } else {
          final savedEmail = await _storage.read(key: 'userEmail');
          targetScreen = CompleteProfileScreen(email: savedEmail ?? '');
        }
      } catch (e) {
        if (!mounted) return;
        _navigateToLogin();
        return;
      }
    } else if (normalizedRole.contains('DOCTOR') || normalizedRole.contains('MEDICO')) {
      targetScreen = const DoctorDashboardScreen();
    } else if (normalizedRole.contains('NURSE') || normalizedRole.contains('ENFERMERO')) {
      targetScreen = const NurseDashboardScreen();
    } else if (normalizedRole.contains('ADMIN')) {
      targetScreen = const AdminDashboardScreen();
    } else {
      targetScreen = const LoginScreen();
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_rounded, size: 90, color: Color(0xFF0D47A1)),
            SizedBox(height: 24),
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
            ),
          ],
        ),
      ),
    );
  }
}