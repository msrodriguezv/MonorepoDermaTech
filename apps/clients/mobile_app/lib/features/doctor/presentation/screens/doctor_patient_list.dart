import 'package:flutter/material.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  // --- DATOS FALSOS (MOCK DATA) ---
  final List<Map<String, dynamic>> _allPatients = [
    {'id': '1', 'name': 'Carlos Pérez', 'dni': '1723456789', 'condition': 'Dermatitis', 'status': 'Activo', 'lastVisit': '08/01/2026'},
    {'id': '2', 'name': 'Maria Rodriguez', 'dni': '1711223344', 'condition': 'Revisión Lunar', 'status': 'Pendiente', 'lastVisit': '15/12/2025'},
    {'id': '3', 'name': 'Jorge Yunda', 'dni': '1755667788', 'condition': 'Acné Severo', 'status': 'Activo', 'lastVisit': '10/11/2025'},
    {'id': '4', 'name': 'Ana Gomez', 'dni': '1799887766', 'condition': 'Rosácea', 'status': 'Inactivo', 'lastVisit': '01/10/2025'},
    {'id': '5', 'name': 'Luis Torres', 'dni': '1712341234', 'condition': 'Psoriasis', 'status': 'Activo', 'lastVisit': '05/01/2026'},
  ];

  // Lista que se mostrará en pantalla (filtrada)
  List<Map<String, dynamic>> _foundPatients = [];

  @override
  void initState() {
    _foundPatients = _allPatients;
    super.initState();
  }

  // Función de búsqueda
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allPatients;
    } else {
      results = _allPatients
          .where((user) =>
              user["name"].toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              user["dni"].contains(enteredKeyword))
          .toList();
    }

    setState(() {
      _foundPatients = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // --- 1. SIDEBAR (Menú Lateral Simplificado) ---
          Container(
            width: 250,
            color: const Color(0xFF0D47A1), // Azul DermaTech
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Icon(Icons.medical_services, size: 50, color: Colors.white),
                const SizedBox(height: 10),
                const Text("PANEL MÉDICO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                
                // Opción: Dashboard
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.white70),
                  title: const Text("Dashboard", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                     // Aquí navegarías de vuelta al dashboard
                     Navigator.pop(context); 
                  },
                ),
                // Opción: Pacientes (Activa)
                Container(
                  color: Colors.white.withOpacity(0.1),
                  child: ListTile(
                    leading: const Icon(Icons.people, color: Colors.white),
                    title: const Text("Mis Pacientes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onTap: () {},
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.white70),
                  title: const Text("Agenda", style: TextStyle(color: Colors.white70)),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // --- 2. CONTENIDO PRINCIPAL ---
          Expanded(
            child: Column(
              children: [
                // HEADER SUPERIOR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text(
                        "Gestión de Pacientes",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
                      ),
                      const Spacer(),
                      // Barra de Búsqueda
                      Container(
                        width: 300,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: TextField(
                          onChanged: (value) => _runFilter(value),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            hintText: "Buscar por nombre o C.I.",
                            contentPadding: EdgeInsets.only(top: 5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Nuevo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),

                // TABLA DE DATOS
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                          columnSpacing: 30,
                          horizontalMargin: 30,
                          columns: const [
                            DataColumn(label: Text("PACIENTE", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("CÉDULA", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("DIAGNÓSTICO", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("ÚLTIMA VISITA", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("ESTADO", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("ACCIONES", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _foundPatients.map((patient) => DataRow(
                            cells: [
                              // Avatar + Nombre
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                                    child: Text(patient['name'][0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(patient['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              )),
                              DataCell(Text(patient['dni'])),
                              DataCell(Text(patient['condition'])),
                              DataCell(Text(patient['lastVisit'])),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: patient['status'] == 'Activo' ? Colors.green.withOpacity(0.1) : 
                                           patient['status'] == 'Pendiente' ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    patient['status'],
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.bold,
                                      color: patient['status'] == 'Activo' ? Colors.green : 
                                             patient['status'] == 'Pendiente' ? Colors.orange : Colors.grey
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                                    onPressed: () {
                                      // Ver detalles
                                    },
                                    tooltip: "Ver Historia Clínica",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                    onPressed: () {},
                                    tooltip: "Editar",
                                  ),
                                ],
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}