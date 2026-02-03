import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../features/patients/data/datasources/patient_remote_data_source.dart';
import '../../data/models/auth_models.dart';
import 'register_screen.dart';
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
  static const Color _dermaNavyBlue = Color(0xFF0A2342);
  static const Color _dermaAccentBlue = Color(0xFF00A8E8);
  static const Color _dermaBackgroundWhite = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  final _storage = StorageService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);

      final TokenResponseModel tokenResponse = await authDataSource.login(
        LoginRequestModel(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );

      if (tokenResponse.accessToken.isEmpty) {
        throw Exception("Authentication failed: Empty access token.");
      }

      await _storage.write(key: 'accessToken', value: tokenResponse.accessToken);
      await _storage.write(key: 'refreshToken', value: tokenResponse.refreshToken);
      await _storage.write(key: 'userRole', value: tokenResponse.role);

      final String fullName = "${tokenResponse.firstName} ${tokenResponse.lastName}";
      await _storage.write(key: 'userName', value: fullName);
      await _storage.write(key: 'userEmail', value: _emailController.text.trim());

      if (!mounted) return;

      await _handleRoleRedirection(tokenResponse, apiClient);
    } catch (error) {
      if (!mounted) return;
      _handleLoginError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRoleRedirection(
      TokenResponseModel user, ApiClient apiClient) async {
    final role = user.role.toUpperCase();

    switch (role) {
      case 'STUDENT':
      case 'PATIENT':
        await _handleStudentFlow(apiClient);
        break;

      case 'DOCTOR':
      case 'MEDICO':
        _navigateTo(const DoctorDashboardScreen());
        break;

      case 'NURSE':
      case 'ENFERMERO':
        _navigateTo(const NurseDashboardScreen());
        break;

      case 'ADMIN':
        _navigateTo(const AdminDashboardScreen());
        break;

      default:
        await _handleStudentFlow(apiClient);
        break;
    }
  }

  Future<void> _handleStudentFlow(ApiClient apiClient) async {
    try {
      final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
      final status = await patientDataSource.getProfileStatus();

      if (!mounted) return;

      if (status.isProfileComplete) {
        _navigateTo(const StudentDashboardScreen());
      } else {
        _navigateTo(CompleteProfileScreen(email: _emailController.text.trim()));
      }
    } catch (e) {
      if (mounted) {
        _navigateTo(CompleteProfileScreen(email: _emailController.text.trim()));
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _handleLoginError(Object error) {
    String displayMessage = "Se produjo un error inesperado";

    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        displayMessage = "Credenciales Incorrectas";
      } else if (error.response?.statusCode == 404) {
        displayMessage = "Usuario no Encontrado";
      } else if (error.type == DioExceptionType.connectionTimeout) {
        displayMessage = "Se agoto el tiempo de conexion con el servidor";
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
                            Container(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Text(
                              'Iniciar Sesion',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _dermaNavyBlue,
                              ),
                            ),
                            const SizedBox(height: 40),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!value.contains('@')) {
                                  return 'Formato de correo invalido';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                label: 'Correo',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: true,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu clave';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                label: 'Clave',
                                icon: Icons.lock_outline,
                              ),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dermaNavyBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Ingresar',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("¿No tienes cuenta aun? ",
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                                GestureDetector(
                                  onTap: () {
                                    if (!_isLoading) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterScreen()),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Registrate',
                                    style: TextStyle(
                                        color: _dermaAccentBlue,
                                        fontWeight: FontWeight.bold),
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

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _dermaNavyBlue.withOpacity(0.6)),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      prefixIcon: Icon(icon, color: _dermaNavyBlue),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
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