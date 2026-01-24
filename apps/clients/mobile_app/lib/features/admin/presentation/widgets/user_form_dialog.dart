import 'package:flutter/material.dart';

class UserFormDialog extends StatefulWidget {
  final String roleTitle; // "Doctores", "Enfermeros", "Pacientes"
  final Color roleColor;

  const UserFormDialog({
    super.key, 
    required this.roleTitle, 
    required this.roleColor
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // --- CONTROLADORES GENERALES ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- CONTROLADORES ESPECÍFICOS (DOCTOR/ENFERMERO) ---
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _officeController = TextEditingController();

  // --- CONTROLADORES ESPECÍFICOS (ESTUDIANTE/PACIENTE) ---
  final _facultyController = TextEditingController();
  final _careerController = TextEditingController();
  final _semesterController = TextEditingController();
  
  // Para la fecha de nacimiento
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    // Detectamos el rol para mostrar/ocultar campos
    final isDoctor = widget.roleTitle.contains("Doctor");
    final isPatient = widget.roleTitle.contains("Paciente");
    final isNurse = widget.roleTitle.contains("Enfermero");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(30),
        width: 600, // Un poco más ancho para que quepan bien los campos
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // --- ENCABEZADO ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add, color: widget.roleColor, size: 32),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nuevo ${widget.roleTitle.substring(0, widget.roleTitle.length - 1)}", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
                    ),
                    const Text("Complete los datos requeridos por la UCE.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 40),

            // --- FORMULARIO SCROLLABLE ---
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. DATOS DE CUENTA (Todos los roles)
                      _sectionTitle("Información de Cuenta"),
                      Row(
                        children: [
                          Expanded(child: _buildInput(_firstNameController, "Nombres", Icons.person)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildInput(_lastNameController, "Apellidos", Icons.person_outline)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildInput(_emailController, "Correo Institucional", Icons.email)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildInput(_passwordController, "Contraseña Temporal", Icons.lock, isPassword: true)),
                        ],
                      ),

                      const SizedBox(height: 25),
                      _sectionTitle("Datos de Contacto"),
                       Row(
                        children: [
                          Expanded(child: _buildInput(_phoneController, "Teléfono / Celular", Icons.phone)),
                          const SizedBox(width: 15),
                          // Picker de Fecha de Nacimiento
                          Expanded(child: _buildDatePicker(context)),
                        ],
                      ),

                      // 2. CAMPOS PARA PERSONAL MÉDICO (Doctor/Enfermero)
                      if (isDoctor || isNurse) ...[
                        const SizedBox(height: 25),
                        _sectionTitle("Información Profesional"),
                        Row(
                          children: [
                            if (isDoctor)
                              Expanded(child: _buildInput(_specializationController, "Especialización", Icons.medical_services)),
                            if (isDoctor) const SizedBox(width: 15),
                            Expanded(child: _buildInput(_licenseController, "Nº Licencia / Registro", Icons.badge)),
                          ],
                        ),
                        if (isDoctor) ...[
                          const SizedBox(height: 15),
                          _buildInput(_officeController, "Nº Consultorio", Icons.meeting_room),
                        ]
                      ],

                      // 3. CAMPOS PARA ESTUDIANTES/PACIENTES
                      if (isPatient) ...[
                        const SizedBox(height: 25),
                        _sectionTitle("Ficha Académica"),
                        Row(
                          children: [
                            Expanded(child: _buildInput(_facultyController, "Facultad", Icons.school)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildInput(_careerController, "Carrera", Icons.menu_book)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildInput(_semesterController, "Semestre Actual", Icons.timeline),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- BOTONES DE ACCIÓN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: _saveUser,
                  icon: const Icon(Icons.save, color: Colors.white, size: 20),
                  label: const Text("Registrar Usuario", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.roleColor,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE GUARDADO ---
  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      // AQUÍ IRÁ LA LLAMADA A TU BACKEND (Dio/Repository)
      // Recolectar datos según el rol...
      
      Navigator.pop(context); // Cierra el modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text("${widget.roleTitle.substring(0, widget.roleTitle.length - 1)} creado exitosamente"),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- WIDGETS AUXILIARES ---
  
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 15)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: (value) => value!.isEmpty ? "Requerido" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.roleColor, width: 2)),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
            const SizedBox(width: 10),
            Text(
              _selectedDate == null 
                ? "Fecha de Nacimiento" 
                : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}