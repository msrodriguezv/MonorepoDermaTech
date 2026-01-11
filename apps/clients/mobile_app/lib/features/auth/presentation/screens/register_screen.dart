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

  /// Handles the registration process.
  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // UX: Show floating snackbar to avoid layout shifts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing registration...'), 
        backgroundColor: _dermaNavyBlue,
        behavior: SnackBarBehavior.floating, // Floats above content
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

      await dataSource.register(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Account created! Please login.'), 
           backgroundColor: Colors.green,
           behavior: SnackBarBehavior.floating,
         ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Clean error message for better UX
      String errorMessage = error.toString().replaceAll('Exception:', '').trim();
      
      // Translation for specific backend errors (Optional but nice)
      if (errorMessage.contains('409')) {
        errorMessage = 'El usuario ya existe. Intenta iniciar sesión.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating, // Crucial: Don't push layout up
          margin: const EdgeInsets.all(20), // Nice spacing
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen size for responsive logic
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: _dermaBackgroundWhite,
      // EXTEND BODY: This makes the body go BEHIND the AppBar, removing the "rectangle" gap at the top.
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: CircleAvatar(
             backgroundColor: Colors.white.withOpacity(0.8), // Slight background for visibility
             child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _dermaNavyBlue, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      // LAYOUT BUILDER: The secret to perfect centering + scrolling
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Forces the container to be exactly the height of the screen
                minHeight: constraints.maxHeight, 
              ),
              child: Center( // This CENTER widget is what vertically aligns everything
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 450), // Web/Desktop limit
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Vertically Center content
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        // --- Logo ---
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

                        // --- Inputs ---
                        
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

                        // --- Actions ---
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(text, style: TextStyle(color: _dermaNavyBlue.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

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