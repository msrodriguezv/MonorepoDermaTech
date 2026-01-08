import 'package:flutter/material.dart';

import 'create_patient_screen.dart';
import 'patient_detail_screen.dart';
class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  // Datos falsos para probar el diseño (luego vendrán del backend)
  final List<Map<String, String>> dummyPatients = const [
    {
      'name': 'Carlos Pérez',
      'dni': '1723456789',
      'email': 'carlos@email.com',
      'status': 'Activo'
    },
    {
      'name': 'Maria Rodriguez',
      'dni': '1711223344',
      'email': 'maria@email.com',
      'status': 'Pendiente'
    },
    {
      'name': 'Jorge Yunda',
      'dni': '1755667788',
      'email': 'jorge@email.com',
      'status': 'Activo'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Pacientes DermaTech',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1), // Azul oscuro institucional
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              // Aquí luego pondremos la lógica de cerrar sesión
              Navigator.pop(context); 
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Listado General',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            // Lista expandible
            Expanded(
              child: ListView.builder(
                itemCount: dummyPatients.length,
                itemBuilder: (context, index) {
                  final patient = dummyPatients[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                        child: Text(
                          patient['name']![0], // Primera letra del nombre
                          style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        patient['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('C.I: ${patient['dni']}'),
                          Text(patient['email']!, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        // Aquí luego iremos al detalle del paciente
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Seleccionaste a ${patient['name']}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Botón flotante para CREAR
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Paciente', style: TextStyle(color: Colors.white)),
        onPressed: () {
          // Navegar a la pantalla de Crear Paciente
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePatientScreen()), 
          );
        },
      ),
    );
  }
}