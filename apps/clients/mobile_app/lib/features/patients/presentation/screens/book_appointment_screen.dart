import 'package:flutter/material.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _symptomsController = TextEditingController();
  
  // Variables de Estado
  String? _selectedDoctor; // <--- NUEVO: Para guardar al doctor
  DateTime? _selectedDate;
  String? _selectedTime;
  
  // Lista de Doctores (Simulada)
  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Alejandro Jácome',
      'specialty': 'Dermatología General',
      'experience': '15 años de exp.',
      'gender': 'male',
    },
    {
      'name': 'Dra. Andrea Salcedo',
      'specialty': 'Dermatología Clínica',
      'experience': '8 años de exp.',
      'gender': 'female',
    },
  ];

  // Horarios simulados
  final List<String> _morningSlots = ['08:00', '09:30', '10:00', '11:30'];
  final List<String> _afternoonSlots = ['14:00', '15:30', '16:00', '17:30'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Agendar Cita", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2342),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- PASO 1: SELECCIONAR MÉDICO (NUEVO) ---
            _sectionHeader("1. Elige tu Especialista", Icons.person_search),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                final isSelected = _selectedDoctor == doctor['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDoctor = doctor['name'];
                      // Opcional: Resetear fecha/hora si cambias de doctor
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE1F5FE) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: isSelected ? const Color(0xFF00A8E8) : Colors.grey[200],
                          child: Icon(
                            doctor['gender'] == 'male' ? Icons.face : Icons.face_3,
                            size: 35,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected ? const Color(0xFF0A2342) : Colors.black,
                                ),
                              ),
                              Text(
                                doctor['specialty'],
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "Disponible",
                                  style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF00A8E8)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // --- PASO 2: SÍNTOMAS ---
            _sectionHeader("2. Describe tus síntomas", Icons.medical_information),
            const SizedBox(height: 10),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ej: Picazón intensa, manchas rojas...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8))),
              ),
            ),

            const SizedBox(height: 30),

            // --- PASO 3: SELECCIONAR FECHA ---
            _sectionHeader("3. Elige una Fecha", Icons.calendar_month),
            const SizedBox(height: 15),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedDate == null ? Colors.grey.shade300 : const Color(0xFF00A8E8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null 
                        ? "Seleccionar día" 
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey : const Color(0xFF0A2342),
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- PASO 4: HORARIOS ---
            if (_selectedDate != null) ...[
              _sectionHeader("4. Horarios Disponibles", Icons.access_time),
              const SizedBox(height: 15),
              const Text("Mañana", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _morningSlots.map((time) => _buildTimeChip(time)).toList(),
              ),
              const SizedBox(height: 15),
              const Text("Tarde", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _afternoonSlots.map((time) => _buildTimeChip(time)).toList(),
              ),
            ],

            const SizedBox(height: 40),

            // --- BOTÓN CONFIRMAR ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                // Validamos que TODO esté lleno
                onPressed: (_selectedDoctor != null && _selectedTime != null && _symptomsController.text.isNotEmpty)
                  ? _confirmAppointment 
                  : null, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE FECHA ---
  Future<void> _pickDate() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Primero selecciona un médico."), backgroundColor: Colors.orange));
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  // --- LÓGICA DE CONFIRMACIÓN ---
  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Resumen de Cita"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow("Médico:", _selectedDoctor!),
            _summaryRow("Fecha:", "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
            _summaryRow("Hora:", _selectedTime!),
            const SizedBox(height: 10),
            const Text("Tu solicitud será revisada por el área de enfermería.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Corregir")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Cita agendada exitosamente"), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2342)),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0A2342)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTime == time;
    return ChoiceChip(
      label: Text(time),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTime = selected ? time : null);
      },
      selectedColor: const Color(0xFF00A8E8),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
    );
  }
}