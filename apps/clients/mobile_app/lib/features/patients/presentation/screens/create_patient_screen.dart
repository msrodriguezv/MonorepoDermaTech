import 'package:flutter/material.dart';

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para capturar el texto
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nuevo Paciente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1), // Azul Institucional
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título de la sección
                const Text(
                  "Información Personal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Ingrese los datos básicos del paciente para registrarlo en el sistema.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 25),

                // --- CAMPOS DEL FORMULARIO ---
                
                // Nombre Completo
                _buildLabel("Nombre Completo"),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration("Ej: Juan Pérez", Icons.person_outline),
                  validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                ),
                const SizedBox(height: 20),

                // Cédula / DNI
                _buildLabel("Cédula de Identidad (DNI)"),
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Ej: 1712345678", Icons.credit_card),
                  validator: (value) => value!.length < 10 ? 'DNI inválido' : null,
                ),
                const SizedBox(height: 20),

                // Email
                _buildLabel("Correo Electrónico"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration("Ej: paciente@email.com", Icons.email_outlined),
                ),
                const SizedBox(height: 20),

                // Teléfono
                _buildLabel("Teléfono Móvil"),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration("Ej: 0991234567", Icons.phone_android),
                ),
                
                const SizedBox(height: 40),

                // BOTÓN DE GUARDAR
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aquí luego conectaremos con el Backend
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Guardando paciente... (Simulado)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Volver a la lista después de "guardar"
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pop(context);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text(
                    "REGISTRAR PACIENTE",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para estilos de inputs
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}