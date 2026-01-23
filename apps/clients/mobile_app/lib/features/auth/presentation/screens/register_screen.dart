import 'package:flutter/material.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/auth_models.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- UI Constants ---
  static const Color _dermaNavyBlue = Color(0xFF0A2342);
  static const Color _dermaAccentBlue = Color(0xFF00A8E8);
  static const Color _dermaBackgroundWhite = Colors.white;

  // --- Form & Controllers ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // --- State Management ---
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Centralized navigation logic to redirect users to the Login Screen.
  /// Used for both successful registration and specific timeout scenarios.
  void _navigateToLogin({required String message, bool isWarning = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isWarning ? Colors.orange[800] : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5), // Longer duration for readability
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  /// Handles the registration process including timeout resilience.
  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // UX: Show floating snackbar to indicate processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing registration... Please wait.'), 
        backgroundColor: _dermaNavyBlue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );

    try {
      final apiClient = ApiClient();
      final dataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);

      final request = RegisterRequestModel(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'STUDENT', 
      );

      // Attempt to register via API
      await dataSource.register(request);

      if (!mounted) return;

      // Happy Path: Immediate success response from backend
      _navigateToLogin(message: 'Account created successfully! Please login.');

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      String errorMessage = error.toString();

      // --- CRITICAL FIX: TIMEOUT HANDLING ---
      // If the backend takes too long (e.g., synchronous email sending), 
      // Dio throws a receive timeout. However, the DB record usually exists.
      // We redirect the user to login instead of showing an error.
      if (errorMessage.contains('receive timeout') || 
          errorMessage.contains('connection timeout') || 
          errorMessage.contains('deadline exceeded')) {
        
        _navigateToLogin(
          message: 'The process took longer than expected, but your account is likely created. Please try logging in.',
          isWarning: true
        );
        return; 
      }
      
      // Handle "User already exists" (409 Conflict)
      if (errorMessage.contains('409')) {
        errorMessage = 'El usuario ya existe. Intenta iniciar sesión.';
      } else {
        // Sanitize technical error messages for the user
        errorMessage = errorMessage
            .replaceAll('Exception:', '')
            .replaceAll('DioException', '')
            .trim();
      }

      // Show standard error snackbar for non-timeout errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Wrapper for cleaner call in happy path
  void _navigateToLoginHelper(String successMessage) {
    _navigateToLogin(message: successMessage);
  }

  @override
  Widget build(BuildContext context) {
    // Screen size for responsive logic
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: _dermaBackgroundWhite,
      // EXTEND BODY: Ensures body content flows behind the transparent AppBar
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: CircleAvatar(
             backgroundColor: Colors.white.withOpacity(0.8),
             child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _dermaNavyBlue, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      // LAYOUT BUILDER: Ensures content is centered but scrollable on small screens
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, 
              ),
              child: Center( 
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 450), // Constraint for web/tablet
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        // --- Logo Asset ---
                        Image.asset(
                          'assets/images/logo.png', 
                          height: isMobile ? 90 : 120, 
                          fit: BoxFit.contain
                        ),
                        
                        // --- Headers ---
                        const SizedBox(height: 20),
                        const Text(
                          'Crear Cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold, 
                            color: _dermaNavyBlue
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Regístrate para continuar', 
                          textAlign: TextAlign.center, 
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600)
                        ),
                        const SizedBox(height: 30),

                        // --- Input Fields ---
                        
                        _buildLabel('Email Institucional'),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: _dermaNavyBlue),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requerido';
                            if (!value.contains('@')) return 'Email inválido';
                            if (!value.endsWith('uce.edu.ec')) return 'Usar correo @uce.edu.ec';
                            return null;
                          },
                          decoration: _inputDecoration(
                            hint: 'usuario@uce.edu.ec', 
                            icon: Icons.email_outlined
                          ),
                        ),
                        const SizedBox(height: 15),

                        _buildLabel('Contraseña'),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: _dermaNavyBlue),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requerido';
                            if (value.length < 8) return 'Mín 8 chars';
                            String pattern = r'((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$';
                            if (!RegExp(pattern).hasMatch(value)) return 'Falta Mayús, Minús, Núm/Símbolo';
                            return null;
                          },
                          decoration: _inputDecoration(
                            hint: '********', 
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            )
                          ),
                        ),
                        const SizedBox(height: 15),

                        _buildLabel('Confirmar Contraseña'),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !_isLoading,
                          obscureText: !_isConfirmPasswordVisible,
                          style: const TextStyle(color: _dermaNavyBlue),
                          validator: (value) {
                            if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                          decoration: _inputDecoration(
                            hint: '********', 
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            )
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- Action Buttons ---
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dermaNavyBlue, 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(vertical: 16), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('REGISTRARSE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿Ya tienes cuenta? ', style: TextStyle(color: Colors.grey.shade600)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                              child: const Text('Inicia Sesión', style: TextStyle(color: _dermaAccentBlue, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
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

  // Helper widget to ensure consistent label styling
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(text, style: TextStyle(color: _dermaNavyBlue.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  // Helper for consistent input decoration styling
  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _dermaNavyBlue, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 15.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _dermaAccentBlue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}