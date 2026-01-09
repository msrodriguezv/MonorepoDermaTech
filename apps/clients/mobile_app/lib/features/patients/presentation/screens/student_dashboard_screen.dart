import 'package:flutter/material.dart';
import '../../../auth/presentation/screens/login_screen.dart';
// IMPORTANTE: Importamos la pantalla de agendar cita
import 'book_appointment_screen.dart'; 

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  // --- DATOS SIMULADOS (Estos vendrían del Login/Registro) ---
  final String studentName = "Carlos Pérez";
  final String faculty = "Facultad de Ingeniería";
  final String career = "Sistemas de Información";
  final String semester = "5to Semestre";
  final String studentCode = "QR-STU-001"; // El código para el Enfermero

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mi Perfil - DermaTech", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2342), // Azul Institucional
        automaticallyImplyLeading: false, // Sin flecha de atrás
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const LoginScreen())
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TARJETA DE PERFIL (DISEÑO MEJORADO)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2342), Color(0xFF00A8E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Color(0xFF0A2342)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hola, $studentName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 5),
                        Text(faculty, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text("$career - $semester", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2. CÓDIGO QR (ACCESO)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text("TU PASE DE ACCESO", style: TextStyle(color: Colors.grey, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // SIMULACIÓN DE CÓDIGO QR VISUAL
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 180, color: Colors.black),
                        Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.white,
                          child: const Icon(Icons.shield, color: Color(0xFF0A2342), size: 30),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                    child: Text(studentCode, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF0A2342))),
                  ),
                  const SizedBox(height: 10),
                  const Text("Presenta este código en Triaje", style: TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // 3. PRÓXIMAS CITAS
            const Text("Próximas Citas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
            const SizedBox(height: 15),
            
            const _AppointmentCard(
              date: "10 Oct, 2025",
              time: "14:30 PM",
              status: "Programada",
              doctor: "Dr. Juan Pérez",
              color: Colors.blue,
            ),
             const _AppointmentCard(
              date: "15 Nov, 2025",
              time: "09:00 AM",
              status: "Pendiente Aprobación",
              doctor: "Por asignar",
              color: Colors.orange,
            ),

            const SizedBox(height: 20),
            
            // 4. BOTÓN SOLICITAR NUEVA CITA (CONECTADO AL FLUJO)
            ElevatedButton.icon(
              onPressed: () {
                // --- NAVEGACIÓN A LA PANTALLA DE AGENDAMIENTO ---
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: const Text("Agendar Nueva Cita", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A8E8),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                shadowColor: const Color(0xFF00A8E8).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Widget Tarjeta de Cita
class _AppointmentCard extends StatelessWidget {
  final String date;
  final String time;
  final String status;
  final String doctor;
  final Color color;

  const _AppointmentCard({
    required this.date,
    required this.time,
    required this.status,
    required this.doctor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2342))),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(doctor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          )
        ],
      ),
    );
  }
}