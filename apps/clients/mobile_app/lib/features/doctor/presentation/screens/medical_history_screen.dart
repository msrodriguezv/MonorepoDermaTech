import 'package:flutter/material.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const MedicalHistoryScreen({
    super.key, 
    required this.patientName, 
    required this.patientId
  });

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los datos médicos
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Historia Clínica: ${widget.patientName}", style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Guardar Cambios",
            onPressed: _saveHistory,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TARJETA DE DATOS DEL PACIENTE ---
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF0D47A1), size: 40),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("C.I: ${widget.patientId}", style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- SECCIÓN 1: DIAGNÓSTICO ---
              _sectionTitle("Diagnóstico Médico", Icons.medical_information),
              const SizedBox(height: 10),
              TextFormField(
                controller: _diagnosisController,
                maxLines: 4,
                decoration: _inputDecoration("Escriba el diagnóstico detallado aquí..."),
                validator: (v) => v!.isEmpty ? "El diagnóstico es obligatorio" : null,
              ),
              
              const SizedBox(height: 30),

              // --- SECCIÓN 2: RECETA MÉDICA ---
              _sectionTitle("Tratamiento / Receta", Icons.medication),
              const SizedBox(height: 10),
              TextFormField(
                controller: _prescriptionController,
                maxLines: 4,
                decoration: _inputDecoration("Medicamentos, dosis y frecuencia..."),
              ),

              const SizedBox(height: 30),

              // --- SECCIÓN 3: NOTAS INTERNAS ---
              _sectionTitle("Notas de Evolución (Privado)", Icons.note_alt),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: _inputDecoration("Observaciones adicionales..."),
              ),

              const SizedBox(height: 40),

              // BOTÓN FINAL GUARDAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveHistory,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("GUARDAR HISTORIA CLÍNICA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveHistory() {
    if (_formKey.currentState!.validate()) {
      // AQUÍ SE CONECTARÍA CON TU BACKEND (MongoDB/Postgres)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Historia actualizada correctamente"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
    );
  }
}