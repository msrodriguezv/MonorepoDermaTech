import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatters
import '../../../../core/network/api_client.dart';
import '../../data/datasources/patient_remote_data_source.dart';
import '../../data/models/update_profile_model.dart';
import 'student_dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email;

  const CompleteProfileScreen({super.key, required this.email});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- UI Constants ---
  static const Color _navyBlue = Color(0xFF0A2342);
  static const Color _cyanBlue = Color(0xFF00A8E8);

  // --- Controllers ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedDate;

  final _facultyController = TextEditingController();
  final _careerController = TextEditingController();
  String? _selectedSemester;

  String? _selectedBloodType;
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _insuranceController = TextEditingController();

  bool _isLoading = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _semesters = List.generate(10, (index) => '${index + 1}');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _facultyController.dispose();
    _careerController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  // --- LOGIC: SUBMIT FORM TO BACKEND ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Prepare the DTO Model
      final profileModel = UpdateProfileModel(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        // Check API date format. Typically YYYY-MM-DD.
        birthDate: _selectedDate!.toIso8601String().split('T')[0], 
        phone: _phoneController.text.trim(),
        faculty: _facultyController.text.trim(),
        career: _careerController.text.trim(),
        currentSemester: int.parse(_selectedSemester!),
        insuranceProvider: _insuranceController.text.trim().isEmpty ? null : _insuranceController.text.trim(),
        bloodType: _selectedBloodType!,
        // Splitting comma-separated strings into Lists
        allergies: _allergiesController.text.isEmpty 
            ? [] 
            : _allergiesController.text.split(',').map((e) => e.trim()).toList(),
        chronicConditions: _conditionsController.text.isEmpty 
            ? [] 
            : _conditionsController.text.split(',').map((e) => e.trim()).toList(),
      );

      // 2. Call the Real Data Source
      // Note: In a real app, use Dependency Injection (GetIt/Riverpod)
      final apiClient = ApiClient(); 
      final dataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
      
      await dataSource.updateProfile(profileModel);

      if (!mounted) return;

      // 3. Success -> Navigate to Dashboard
      final fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboardScreen(studentName: fullName),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error guardando perfil: ${e.toString().replaceAll('Exception:', '')}"),
          backgroundColor: Colors.redAccent,
        )
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Keep _selectDate method as is) ...
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year - 16, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastDate,
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) => Theme(
         data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _navyBlue, onPrimary: Colors.white, onSurface: _navyBlue)),
         child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completar Perfil"), backgroundColor: _navyBlue, automaticallyImplyLeading: false, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // ... (Headers same as before) ...
               const Text("¡Casi terminamos!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navyBlue), textAlign: TextAlign.center),
               const SizedBox(height: 30),

               // --- PERSONAL INFO ---
               _buildTextField(
                 controller: _firstNameController, 
                 label: "Nombres", 
                 icon: Icons.person,
                 // VALIDATION: Only letters and spaces
                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'))],
                 validator: (val) {
                   if (val == null || val.isEmpty) return "Requerido";
                   if (val.length < 3) return "Mínimo 3 letras";
                   return null;
                 }
               ),
               const SizedBox(height: 15),
               _buildTextField(
                 controller: _lastNameController, 
                 label: "Apellidos", 
                 icon: Icons.person_outline,
                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'))],
                 validator: (val) {
                   if (val == null || val.isEmpty) return "Requerido";
                   if (val.length < 3) return "Mínimo 3 letras";
                   return null;
                 }
               ),
               
               const SizedBox(height: 15),
               TextFormField(
                controller: _birthDateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => value == null || value.isEmpty ? "Fecha requerida" : null,
                decoration: _inputDecoration("Fecha de Nacimiento", Icons.calendar_today),
              ),

               const SizedBox(height: 15),
               _buildTextField(
                 controller: _phoneController, 
                 label: "Celular (10 dígitos)", 
                 icon: Icons.phone,
                 keyboardType: TextInputType.phone,
                 // VALIDATION: Only numbers, max 10
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                   LengthLimitingTextInputFormatter(10),
                 ],
                 validator: (val) {
                   if (val == null || val.isEmpty) return "Requerido";
                   if (val.length != 10) return "Debe tener 10 dígitos";
                   if (!val.startsWith('09')) return "Debe empezar con 09"; // Ecuador standard
                   return null;
                 }
               ),

               const SizedBox(height: 30),
               // --- ACADEMIC ---
               _buildTextField(controller: _facultyController, label: "Facultad", icon: Icons.account_balance),
               const SizedBox(height: 15),
               _buildTextField(controller: _careerController, label: "Carrera", icon: Icons.school_outlined),
               const SizedBox(height: 15),
               DropdownButtonFormField<String>(
                value: _selectedSemester,
                items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text("$s° Semestre"))).toList(),
                onChanged: (val) => setState(() => _selectedSemester = val),
                validator: (val) => val == null ? "Seleccione semestre" : null,
                decoration: _inputDecoration("Semestre", Icons.timeline),
              ),

              const SizedBox(height: 30),
              // --- MEDICAL ---
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                items: _bloodTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => _selectedBloodType = val),
                validator: (val) => val == null ? "Tipo de sangre requerido" : null,
                decoration: _inputDecoration("Tipo de Sangre", Icons.bloodtype),
              ),
              const SizedBox(height: 15),
              _buildTextField(controller: _allergiesController, label: "Alergias (Opcional)", icon: Icons.warning_amber_rounded, isRequired: false),
              const SizedBox(height: 15),
              _buildTextField(controller: _conditionsController, label: "Enf. Crónicas (Opcional)", icon: Icons.healing, isRequired: false),
              const SizedBox(height: 15),
              _buildTextField(controller: _insuranceController, label: "Seguro (Opcional)", icon: Icons.health_and_safety, isRequired: false),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyanBlue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text("GUARDAR Y CONTINUAR", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? (isRequired 
        ? (value) => value == null || value.trim().isEmpty ? "Campo requerido" : null
        : null),
      decoration: _inputDecoration(label, icon),
      style: const TextStyle(color: _navyBlue),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _navyBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
    );
  }
}