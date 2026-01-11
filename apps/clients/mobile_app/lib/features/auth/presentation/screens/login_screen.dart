import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Ensure this dependency is in pubspec.yaml

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/auth_models.dart';
import 'register_screen.dart';

// --- DASHBOARD IMPORTS (ROLES) ---
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
  // --- Theme Constants (UI Preserved) ---
  static const Color _dermaNavyBlue = Color(0xFF0A2342);
  static const Color _dermaAccentBlue = Color(0xFF00A8E8);
  static const Color _dermaBackgroundWhite = Colors.white;

  // --- Form & Controllers ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- State Management ---
  // Controls the loading state of the login button to prevent double submission
  bool _isLoading = false;

  // --- Secure Storage ---
  // Instance to persist the JWT token securely on the device
  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- REAL AUTHENTICATION LOGIC ---
  Future<void> _submitLogin() async {
    // 1. Validate Form Input
    if (!_formKey.currentState!.validate()) return;

    // 2. Set Loading State (Updates UI)
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Initialize Dependencies (Dependency Injection could be used here in the future)
      final apiClient = ApiClient();
      final dataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);

      // 4. Perform HTTP Request to Backend
      // This sends the email/password to http://10.0.2.2:3000/api/v1/auth/login
      final TokenResponseModel tokenResponse = await dataSource.login(
        LoginRequestModel(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );

      // 5. Persist Token
      // Save the Access Token for subsequent authenticated requests (e.g., Patient Service)
      await _storage.write(key: 'accessToken', value: tokenResponse.accessToken);
      
      // Debug log to verify connection in console
      print('✅ LOGIN SUCCESS. Token stored: ${tokenResponse.accessToken.substring(0, 15)}...');

      if (!mounted) return;

      // 6. Navigation Logic
      // NOTE: In a full implementation, the Role should be decoded from the JWT Token.
      // For this phase, we keep the email-based routing temporarily to test different Dashboards,
      // but strictly triggered ONLY after a successful backend response.
      _navigateBasedOnEmailRole(_emailController.text.toLowerCase().trim());

    } catch (error) {
      // 7. Error Handling
      // Displays the specific error message from the backend (e.g., "Invalid credentials")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // 8. Reset Loading State
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Routing logic helper.
  /// Decides which dashboard to open based on email hints.
  void _navigateBasedOnEmailRole(String email) {
    Widget destination;

    if (email.contains('admin')) {
      destination = const AdminDashboardScreen();
    } else if (email.contains('doc') || email.contains('medico')) {
      destination = const DoctorDashboardScreen();
    } else if (email.contains('enf')) {
      destination = const NurseDashboardScreen();
    } else {
      // Default for Students/Patients
      destination = const StudentDashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dermaBackgroundWhite,
      // --- APP BAR ---
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
                            
                            // --- Logo Section ---
                            Container(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // --- Title ---
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

                            // --- Inputs ---
                            
                            // Email
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading, // Disable input while loading
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

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading, // Disable input while loading
                              obscureText: true,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingrese su contraseña';
                                if (value.length < 3) return 'Contraseña muy corta'; // Adjusted for flexibility
                                return null;
                              },
                              decoration: _inputDecoration(
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- Login Button ---
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitLogin, // Disable if loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dermaNavyBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 5,
                                shadowColor: _dermaNavyBlue.withOpacity(0.5),
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

                            // --- Navigation ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("¿No tienes cuenta? ", style: TextStyle(color: Colors.grey.shade600)),
                                GestureDetector(
                                  onTap: () {
                                    // Ensure navigation is allowed even if form is dirty
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