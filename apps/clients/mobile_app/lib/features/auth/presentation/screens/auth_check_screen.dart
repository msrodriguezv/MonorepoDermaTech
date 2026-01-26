import 'package:flutter/material.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';

// --- CORE & DATA SOURCE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../patients/data/datasources/patient_remote_data_source.dart';

// --- AUTH & LOGIN IMPORTS ---
import 'login_screen.dart';

// --- DASHBOARD IMPORTS ---
import '../../../patients/presentation/screens/student_dashboard_screen.dart';
import '../../../patients/presentation/screens/complete_profile_screen.dart'; // ✅ Required for redirection
import '../../../doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../nurse/presentation/screens/nurse_dashboard_screen.dart';

/// **AuthCheckScreen**
/// Acts as the initial "Splash Screen" and logic controller for session persistence.
///
/// **Responsibility:**
/// 1. Initialize the application state.
/// 2. Check for the existence of a persisted JWT using the unified StorageService.
/// 3. Route the user to the appropriate Dashboard based on their Role (RBAC).
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  // Instance of the unified storage service (Web-safe)
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _initializeSessionCheck();
  }

  /// Performs the asynchronous check of the user's session state.
  Future<void> _initializeSessionCheck() async {
    // Artificial delay to prevent screen flickering (optional UX improvement).
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Retrieve sensitive session data using the Web-safe wrapper.
      final String? accessToken = await _storage.read(key: 'accessToken');
      final String? userRole = await _storage.read(key: 'userRole');
      final String? userName = await _storage.read(key: 'userName');

      // Validation Logic:
      // If the token and role exist, we proceed to determine the destination.
      if (accessToken != null && accessToken.isNotEmpty && userRole != null) {
        if (!mounted) return;
        // ✅ CRITICAL STEP: Call the async navigation logic to check profile status if needed.
        await _decideNavigationAndRedirect(userRole, userName);
      } else {
        // No valid session found, redirect to Login.
        if (!mounted) return;
        _navigateToLogin();
      }
    } catch (error) {
      debugPrint("❌ Session restoration failed: $error");
      if (mounted) _navigateToLogin();
    }
  }

  /// **_decideNavigationAndRedirect**
  /// Routes the user to the specific dashboard based on the provided Role.
  /// Handles the "Force Profile Completion" check specifically for Students.
  Future<void> _decideNavigationAndRedirect(String role, String? userName) async {
    final String normalizedRole = role.toUpperCase().trim();
    Widget targetScreen;

    // --- ROUTING LOGIC SWITCH ---

    // 1. STUDENT CASE: Strict Profile Verification (F5 Fix)
    if (normalizedRole == 'STUDENT' || normalizedRole == 'PATIENT') {
      try {
        // Inject dependencies manually
        final apiClient = ApiClient();
        final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);

        // API Call: Check if the profile is fully registered in the backend
        final status = await patientDataSource.getProfileStatus();

        if (status.isProfileComplete) {
          targetScreen = StudentDashboardScreen(studentName: userName ?? "Student");
        } else {
          debugPrint("⚠️ Incomplete profile detected on reload. Redirecting to Complete Profile.");
          
          // Retrieve email for the completion screen (saved during login)
          final savedEmail = await _storage.read(key: 'userEmail');
          targetScreen = CompleteProfileScreen(email: savedEmail ?? '');
        }
      } catch (e) {
        debugPrint("❌ Error verifying student status: $e");
        // Fail-safe: If verification fails (e.g., network error), redirect to Login for security.
        if (!mounted) return;
        _navigateToLogin();
        return;
      }
    } 
    // 2. OTHER ROLES: Direct Pass-through (Logic remains unchanged)
    // Doctors, Nurses, and Admins do not need profile verification here.
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
      debugPrint("⚠️ Unknown role detected: $normalizedRole. Redirecting to Login.");
      targetScreen = const LoginScreen();
    }

    if (!mounted) return;

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
            const Icon(Icons.local_hospital_rounded, size: 90, color: Color(0xFF0D47A1)),
            const SizedBox(height: 24),
            
            // Loading Indicator
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}