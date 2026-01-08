import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; 
import '../../data/datasources/auth_remote_data_source.dart'; 
import '../../data/datasources/auth_local_data_source.dart'; 
import '../../data/repositories/auth_repository_impl.dart'; 
import 'register_screen.dart';

import '../../../patients/presentation/screens/patient_list_screen.dart';
/// Responsive Login Screen connected to Backend + Secure Storage.
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE LOGIN REAL (Guardada para después) ---
  void _submitLogin() async { 
    if (_formKey.currentState!.validate()) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conectando con el servidor...'),
          backgroundColor: _dermaNavyBlue,
        ),
      );

      try {
        final dio = Dio(); 
        
        final remoteDS = AuthRemoteDataSource(dio: dio);
        final localDS = AuthLocalDataSource(); 
        
        final repository = AuthRepositoryImpl(
          remoteDataSource: remoteDS,
          localDataSource: localDS, 
        );

        await repository.login(
          _emailController.text.trim(), 
          _passwordController.text.trim()
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientListScreen()), // <--- ESTO ES LO CORRECTO
        );

      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dermaBackgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _dermaNavyBlue),
          onPressed: () => Navigator.pop(context),
        ),
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
                              obscureText: true,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingrese su contraseña';
                                if (value.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                              decoration: _inputDecoration(
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- Login Button (MODIFICADO) ---
                            ElevatedButton(
                              // CAMBIO AQUÍ: Navegación directa para ver diseño
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PatientListScreen()),
                                );
                              },
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
                              child: const Text(
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                    );
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