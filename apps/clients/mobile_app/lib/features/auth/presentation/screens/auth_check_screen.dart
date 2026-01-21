import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- AUTH & LOGIN IMPORTS ---
import 'login_screen.dart';

// --- DASHBOARD IMPORTS (CRITICAL FIX) ---
// We must import the specific files where the Dashboard classes are defined.
import '../../../patients/presentation/screens/student_dashboard_screen.dart';
import '../../../doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../nurse/presentation/screens/nurse_dashboard_screen.dart';

/// **AuthCheckScreen**
/// Acts as the initial "Splash Screen" and logic controller for session persistence.
///
/// **Responsibility:**
/// 1. Initialize the application state.
/// 2. Check for the existence of a persisted JWT (JSON Web Token) in Secure Storage.
/// 3. Route the user to the appropriate Dashboard based on their Role (RBAC).
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  // Instance of the secure storage to retrieve session credentials.
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeSessionCheck();
  }

  /// Performs the asynchronous check of the user's session state.
  Future<void> _initializeSessionCheck() async {
    // Artificial delay to prevent screen flickering (optional).
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Retrieve sensitive session data from encrypted storage.
      final String? accessToken = await _storage.read(key: 'accessToken');
      final String? userRole = await _storage.read(key: 'userRole');
      final String? userName = await _storage.read(key: 'userName');

      // Validation Logic:
      if (accessToken != null && accessToken.isNotEmpty && userRole != null) {
        if (!mounted) return;
        _navigateToDashboard(userRole, userName);
      } else {
        if (!mounted) return;
        _navigateToLogin();
      }
    } catch (error) {
      debugPrint("Session restoration failed: $error");
      if (mounted) _navigateToLogin();
    }
  }

  /// Routes the user to the specific dashboard based on the provided Role.
  /// Implements Role-Based Access Control (RBAC) navigation logic.
  void _navigateToDashboard(String role, String? userName) {
    final String normalizedRole = role.toUpperCase().trim();
    Widget targetScreen;

    // --- ROUTING LOGIC SWITCH ---
    
    if (normalizedRole == 'STUDENT' || normalizedRole == 'PATIENT') {
      // Students require the name parameter
      targetScreen = StudentDashboardScreen(
        studentName: userName ?? "Student",
      );
    } 
    else if (normalizedRole.contains('DOCTOR') || normalizedRole.contains('MEDICO')) {
      targetScreen = const DoctorDashboardScreen();
    } 
    else if (normalizedRole.contains('NURSE') || normalizedRole.contains('ENFERMERO')) {
      targetScreen = const NurseDashboardScreen();
    } 
    else if (normalizedRole.contains('ADMIN')) {
      targetScreen = const AdminDashboardScreen();
    } 
    else {
      // Fallback for unknown roles
      debugPrint("Unknown role detected: $normalizedRole. Redirecting to Login.");
      targetScreen = const LoginScreen();
    }

    // Navigation: Use pushAndRemoveUntil to clear the splash screen from history.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
  }

  /// Directs the user to the Login screen.
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI: Minimalist loading screen with branding.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Branding Logo
            // Ensure you have an asset at 'assets/images/logo.png'
            // If not, this Icon serves as a placeholder.
            const Icon(Icons.local_hospital_rounded, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 24),
            
            // Loading Indicator
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 16),
            
            // // User Feedback
            // const Text(
            //   "Verifying session...",
            //   style: TextStyle(
            //     color: Colors.grey,
            //     fontSize: 14,
            //     letterSpacing: 1.2,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}