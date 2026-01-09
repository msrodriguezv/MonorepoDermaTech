import 'package:flutter/material.dart';
import '../../../patients/presentation/screens/student_dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email; // Recibimos el email del paso anterior

  const CompleteProfileScreen({super.key, required this.email});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para StudentProfiles
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _careerCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  
  DateTime? _birthDate;
  String? _selectedFaculty;
  bool _isLoading = false;

  final List<String> _faculties = [
    'Ingeniería',
    'Ciencias Médicas',
    'Artes',
    'Administración',
    'Jurisprudencia'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Completar Perfil", style: TextStyle(color: Color(0xFF0A2342))),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No dejamos volver atrás para obligar a terminar
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "¡Ya casi estás listo!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
                ),
                const SizedBox(height: 10),
                Text(
                  "Para generar tu código QR, necesitamos tus datos académicos asociados a: ${widget.email}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // --- DATOS PERSONALES ---
                _sectionTitle("Datos Personales"),
                Row(
                  children: [
                    Expanded(child: _buildInput(_firstNameCtrl, "Nombres", Icons.person)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildInput(_lastNameCtrl, "Apellidos", Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildInput(_phoneCtrl, "Teléfono / Celular", Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 15),
                _buildDatePicker(),

                const SizedBox(height: 30),

                // --- DATOS ACADÉMICOS ---
                _sectionTitle("Ficha Académica"),
                DropdownButtonFormField<String>(
                  value: _selectedFaculty,
                  items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _selectedFaculty = v),
                  decoration: _inputDecoration("Facultad", Icons.school),
                  validator: (v) => v == null ? "Seleccione su facultad" : null,
                ),
                const SizedBox(height: 15),
                _buildInput(_careerCtrl, "Carrera", Icons.menu_book),
                const SizedBox(height: 15),
                _buildInput(_semesterCtrl, "Semestre Actual", Icons.timeline, type: TextInputType.number),

                const SizedBox(height: 40),

                // --- BOTÓN FINAL ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfileAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A8E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("GUARDAR Y ACCEDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveProfileAndContinue() async {
    if (_formKey.currentState!.validate()) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingrese su fecha de nacimiento")));
        return;
      }

      setState(() => _isLoading = true);

      // AQUÍ SE GUARDARÍA EN LA BD (TABLA StudentProfiles)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Redirigimos al Dashboard del Estudiante
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
      }
    }
  }

  // --- HELPERS ---
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: (v) => v!.isEmpty ? "Requerido" : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1980),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _birthDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              _birthDate == null ? "Fecha de Nacimiento" : "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}",
              style: TextStyle(color: _birthDate == null ? Colors.grey[700] : Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}