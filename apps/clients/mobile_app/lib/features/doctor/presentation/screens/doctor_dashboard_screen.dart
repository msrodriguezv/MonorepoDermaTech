import 'package:flutter/material.dart';
// 1. RUTA AL LOGIN
import '../../../auth/presentation/screens/login_screen.dart';
// 2. NUEVO IMPORT: Para poder navegar a la Historia Clínica
import 'medical_history_screen.dart'; 

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // LAYOUT BUILDER PARA RESPONSIVIDAD
    return LayoutBuilder(
      builder: (context, constraints) {
        // Definimos "Móvil" si el ancho es menor a 800px
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              isMobile ? "Panel Médico" : "Panel Médico - DermaTech UCE", 
              style: const TextStyle(color: Colors.white, fontSize: 18)
            ),
            backgroundColor: const Color(0xFF0D47A1),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: "Cerrar Sesión",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(width: 10),
              if (!isMobile) ...[ 
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(width: 20),
              ]
            ],
          ),
          // Usamos ListView para tener scroll en toda la página
          body: ListView( 
            padding: const EdgeInsets.all(20.0),
            children: [
              // --- SECCIÓN ESTADÍSTICAS (RESPONSIVE) ---
              Wrap(
                spacing: 15, 
                runSpacing: 15, 
                children: [
                  _StatCard(
                    title: "Pacientes Totales", 
                    count: "125", 
                    color: Colors.blue, 
                    width: isMobile ? constraints.maxWidth : 250 
                  ),
                  _StatCard(
                    title: "Consultas Hoy", 
                    count: "8", 
                    color: Colors.green, 
                    width: isMobile ? constraints.maxWidth : 250
                  ),
                  _StatCard(
                    title: "Pendientes", 
                    count: "3", 
                    color: Colors.orange, 
                    width: isMobile ? constraints.maxWidth : 250
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              const Text(
                "Pacientes Recientes",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // --- GRILLA DE PACIENTES (RESPONSIVE) ---
              GridView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), 
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4, 
                  childAspectRatio: isMobile ? 0.8 : 1.1, 
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return const _PatientCard(); 
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// WIDGET TARJETA DE ESTADÍSTICA
// ============================================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final MaterialColor color;
  final double width; 

  const _StatCard({
    super.key,
    required this.title, 
    required this.count, 
    required this.color,
    required this.width
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET TARJETA DE PACIENTE (MODIFICADO CON ACCIONES)
// ============================================================================
class _PatientCard extends StatelessWidget {
  const _PatientCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue, 
              child: Icon(Icons.person, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 8),
            const Text(
              "Carlos Pérez", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const Text("1712345678", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            
            // Etiqueta de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("Pendiente", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            
            const Spacer(),
            
            const Divider(), // Línea divisoria para las acciones
            
            // --- AQUÍ ESTÁN LOS BOTONES NUEVOS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Ver Perfil Rápido
                InkWell(
                  onTap: () {}, // Acción futura: Ver modal de perfil
                  child: const Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Icon(Icons.visibility_outlined, color: Colors.grey, size: 20),
                  ),
                ),
                
                // 2. Botón Principal: HISTORIA CLÍNICA
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // NAVEGACIÓN A LA PANTALLA DE EDICIÓN
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicalHistoryScreen(
                            patientName: "Carlos Pérez",
                            patientId: "1712345678",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(vertical: 0), 
                      minimumSize: const Size(0, 30), // Botón compacto
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Historia", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}