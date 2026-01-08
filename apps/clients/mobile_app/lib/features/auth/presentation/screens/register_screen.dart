import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; 
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_local_data_source.dart'; // <--- 1. IMPORTAR LOCAL
import '../../data/repositories/auth_repository_impl.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _dermaNavyBlue = Color(0xFF0A2342);
  static const Color _dermaAccentBlue = Color(0xFF00A8E8);
  static const Color _dermaBackgroundWhite = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creando cuenta...'), backgroundColor: _dermaNavyBlue),
      );

      try {
        final dio = Dio();
        final remoteDS = AuthRemoteDataSource(dio: dio);
        final localDS = AuthLocalDataSource(); // <--- 2. CREAR INSTANCIA LOCAL

        // 3. PASAR AMBAS AL REPOSITORIO
        final repository = AuthRepositoryImpl(
          remoteDataSource: remoteDS,
          localDataSource: localDS, 
        );

        await repository.register(
          _emailController.text.trim(), 
          _passwordController.text.trim(),
          "Usuario Nuevo" 
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('¡Cuenta creada! Inicia sesión.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (El resto del diseño visual se mantiene igual que antes) ...
    // Para no hacer el código gigante, asumo que mantienes el mismo build()
    // Si necesitas el código visual completo de nuevo, pídemelo.
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
                            Container(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Image.asset('assets/images/logo.png', height: 120, fit: BoxFit.contain),
                            ),
                            const Text(
                              'Crear Cuenta',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _dermaNavyBlue),
                            ),
                            const SizedBox(height: 10),
                            Text('Regístrate para continuar', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                            const SizedBox(height: 40),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
                              decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: _dermaNavyBlue), filled: true, fillColor: const Color(0xFFF5F7FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: _dermaNavyBlue),
                              validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                              decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline, color: _dermaNavyBlue), filled: true, fillColor: const Color(0xFFF5F7FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: _submitRegister,
                              style: ElevatedButton.styleFrom(backgroundColor: _dermaNavyBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: const Text('REGISTRARSE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 20),
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
}