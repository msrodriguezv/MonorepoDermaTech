import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../features/patients/data/datasources/patient_remote_data_source.dart';
import '../../data/models/auth_models.dart';
import 'register_screen.dart';

// --- DASHBOARD IMPORTS (REAL FEATURE MODULES) ---
import '../../../patients/presentation/screens/complete_profile_screen.dart';
import '../../../patients/presentation/screens/student_dashboard_screen.dart';
import '../../../nurse/presentation/screens/nurse_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../doctor/presentation/screens/doctor_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Theme Constants ---
  static const Color _dermaNavyBlue = Color(0xFF0A2342);
  static const Color _dermaAccentBlue = Color(0xFF00A8E8);
  static const Color _dermaBackgroundWhite = Colors.white;

  // --- Form & Controllers ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- State Management ---
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Executes the authentication flow with Role-Based Access Control (RBAC).
  /// 
  /// Flow:
  /// 1. Validate Inputs.
  /// 2. Request Login (Auth Service).
  /// 3. Persist Tokens & Role.
  /// 4. Route User based on Backend Role (Admin, Doctor, Nurse, Student).
  Future<void> _submitLogin() async {
    // 1. Input Validation
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 2. Dependency Initialization
      // ApiClient includes the AuthInterceptor for future requests.
      final apiClient = ApiClient();
      final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);

      // 3. Authentication Request
      final TokenResponseModel tokenResponse = await authDataSource.login(
        LoginRequestModel(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );

      // --- CRITICAL CHECK ---
      if (tokenResponse.accessToken.isEmpty) {
         throw Exception("Authentication failed: Server returned an empty token.");
      }

      // 4. Persistence Layer
      // Store Access Token, Refresh Token, and the User Role for session management.
      const storage = FlutterSecureStorage();
      await storage.write(key: 'accessToken', value: tokenResponse.accessToken);
      await storage.write(key: 'refreshToken', value: tokenResponse.refreshToken);
      await storage.write(key: 'userRole', value: tokenResponse.role); // Save role for auto-login checks

      print("✅ Login Success. Role: ${tokenResponse.role}");

      if (!mounted) return;

      // 5. Dynamic Routing Strategy
      await _handleRoleRedirection(tokenResponse, apiClient);

    } catch (error) {
      if (!mounted) return;
      _handleLoginError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Routes the user to the correct Dashboard based on the Role returned by the Backend.
  Future<void> _handleRoleRedirection(TokenResponseModel user, ApiClient apiClient) async {
    final role = user.role.toUpperCase();

    switch (role) {
      case 'STUDENT':
      case 'PATIENT': 
        // Students require an extra check: Profile Completeness.
        await _handleStudentFlow(apiClient, user);
        break;

      case 'DOCTOR':
      case 'MEDICO':
        // Direct access for Medical Staff
        _navigateTo(const DoctorDashboardScreen());
        break;

      case 'NURSE':
      case 'ENFERMERO':
        // Direct access for Nursing Staff
        _navigateTo(const NurseDashboardScreen());
        break;

      case 'ADMIN':
        // Direct access for Administrators
        _navigateTo(const AdminDashboardScreen());
        break;

      default:
        // Fail-safe: If role is unrecognized, default to Student flow or show error.
        debugPrint("⚠️ Unknown role: $role. Defaulting to Student flow.");
        await _handleStudentFlow(apiClient, user);
        break;
    }
  }

  /// Specific logic for Students: Checks if the medical profile is complete.
  Future<void> _handleStudentFlow(ApiClient apiClient, TokenResponseModel user) async {
    try {
      final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
      
      // Check Profile Status (Token injected by Interceptor)
      final status = await patientDataSource.getProfileStatus();
      
      if (!mounted) return;

      if (status.isProfileComplete) {
        // Happy Path -> Dashboard
        final fullName = "${user.firstName} ${user.lastName}";
        _navigateTo(StudentDashboardScreen(studentName: fullName));
      } else {
        // Incomplete Path -> Complete Profile Form
        _navigateTo(CompleteProfileScreen(email: _emailController.text.trim()));
      }
    } catch (e) {
      debugPrint("❌ Profile check failed: $e");
      // Fallback: assume incomplete if check fails, or show error
      _navigateTo(CompleteProfileScreen(email: _emailController.text.trim()));
    }
  }

  /// Helper to push replacement routes cleanly.
  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Centralized Error Handling for UI feedback.
  void _handleLoginError(Object error) {
    String displayMessage = "Ocurrió un error inesperado.";

    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        displayMessage = "Credenciales incorrectas.";
      } else if (error.response?.statusCode == 404) {
        displayMessage = "Usuario no encontrado.";
      } else if (error.type == DioExceptionType.connectionTimeout) {
        displayMessage = "Sin conexión al servidor.";
      } else {
        final backendMsg = error.response?.data['message'];
        if (backendMsg != null) displayMessage = backendMsg.toString();
      }
    } else {
      displayMessage = error.toString().replaceAll('Exception:', '').trim();
    }
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- UI Implementation (Same design as before) ---
    return Scaffold(
      backgroundColor: _dermaBackgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            
                            // Logo
                            Container(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),

                            const Text(
                              'Ingresar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _dermaNavyBlue,
                              ),
                            ),
                            
                            const SizedBox(height: 40),

                            // Email Input
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingrese su correo';
                                if (!value.contains('@')) return 'Correo no válido';
                                return null;
                              },
                              decoration: _inputDecoration(
                                label: 'Email',
                                icon: Icons.email_outlined,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: true,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingrese su contraseña';
                                return null;
                              },
                              decoration: _inputDecoration(
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Login Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dermaNavyBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading 
                                ? const SizedBox(
                                    height: 24, 
                                    width: 24, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                  )
                                : const Text(
                                    'ENTRAR',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                            ),

                            const SizedBox(height: 20),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("¿No tienes cuenta? ", style: TextStyle(color: Colors.grey.shade600)),
                                GestureDetector(
                                  onTap: () {
                                    if (!_isLoading) {
                                        Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                        );
                                    }
                                  },
                                  child: const Text(
                                    'Regístrate',
                                    style: TextStyle(color: _dermaAccentBlue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _dermaNavyBlue.withOpacity(0.6)),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      prefixIcon: Icon(icon, color: _dermaNavyBlue),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: _dermaAccentBlue, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
      ),
    );
  }
}