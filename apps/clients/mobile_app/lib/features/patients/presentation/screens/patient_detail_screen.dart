import 'package:flutter/material.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map<String, String> patientData;

  const PatientDetailScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    // Datos falsos de historial médico para visualizar el diseño
    final List<Map<String, String>> history = [
      {'date': '08/01/2026', 'diagnosis': 'Dermatitis Atópica', 'doctor': 'Dr. Silva'},
      {'date': '15/12/2025', 'diagnosis': 'Revisión Lunar', 'doctor': 'Dra. López'},
      {'date': '10/11/2025', 'diagnosis': 'Acné Severo', 'doctor': 'Dr. Silva'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Perfil del Paciente', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Aquí irá la lógica de editar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de editar próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- CABECERA CON DATOS ---
            Container(
              color: const Color(0xFF0D47A1),
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20, top: 10),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      patientData['name']![0],
                      style: const TextStyle(fontSize: 40, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    patientData['name']!,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    patientData['email']!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // Tarjetas de info rápida
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBadge(Icons.credit_card, patientData['dni']!),
                      _infoBadge(Icons.phone, "0991234567"), // Teléfono dummy
                      _infoBadge(Icons.calendar_today, "25 años"), // Edad dummy
                    ],
                  ),
                ],
              ),
            ),

            // --- SECCIÓN DE HISTORIAL ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Historial de Consultas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
                  ),
                  const SizedBox(height: 15),
                  
                  // Lista de consultas previas
                  ...history.map((record) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medical_services, color: Color(0xFF0D47A1)),
                      ),
                      title: Text(
                        record['diagnosis']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("${record['date']} - ${record['doctor']}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {
                        // Ver detalle de la consulta
                      },
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Agregar nueva consulta
        },
        backgroundColor: const Color(0xFF00A8E8),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Nueva Consulta", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}