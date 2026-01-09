import 'package:flutter/material.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  // Lista simulada de estudiantes esperados en el sistema
  // En la vida real, esto vendría de tu Base de Datos al escanear
  final Map<String, dynamic> _studentDatabase = {
    'QR-STU-001': {'name': 'Carlos Pérez', 'faculty': 'Ingeniería', 'id': '1712345678'},
    'QR-STU-002': {'name': 'Ana Gómez', 'faculty': 'Medicina', 'id': '1723456789'},
    'QR-STU-003': {'name': 'Luis Toapanta', 'faculty': 'Artes', 'id': '1734567890'},
  };

  // --- LÓGICA PRINCIPAL: ESCANEAR Y LUEGO EVALUAR ---
  void _startScanProcess() async {
    // 1. Abrimos la cámara (Simulada por ahora)
    // Esperamos a que la cámara nos devuelva un código
    final String? scannedCode = await showDialog<String>(
      context: context,
      builder: (_) => const _FakeCameraScanner(),
    );

    // 2. Verificamos si se escaneó algo
    if (scannedCode != null && mounted) {
      // 3. Verificamos si el código existe en nuestra base
      if (_studentDatabase.containsKey(scannedCode)) {
        final student = _studentDatabase[scannedCode];
        
        // Feedback de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Estudiante identificado: ${student['name']}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // 4. ABRIMOS EL TRIAJE AUTOMÁTICAMENTE
        showDialog(
          context: context,
          builder: (_) => _TriageDialog(
            patientName: student['name'],
            patientId: student['id'],
            faculty: student['faculty'],
          ),
        );
      } else {
        // Código inválido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Código QR no válido o estudiante no encontrado."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Estación de Enfermería - Triaje", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[700],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),
      // --- BOTÓN FLOTANTE GRANDE PARA ESCANEAR ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScanProcess,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.qr_code_scanner, size: 30),
        label: const Text("ESCANEAR ESTUDIANTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ESTADÍSTICAS
            Row(
              children: [
                _InfoCard(title: "Atenciones Hoy", count: "12", color: Colors.teal),
                const SizedBox(width: 15),
                _InfoCard(title: "Derivados a Dr.", count: "4", color: Colors.blue),
              ],
            ),
            const SizedBox(height: 30),
            
            const Text("Historial Reciente", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Pacientes evaluados el día de hoy.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),

            // 2. LISTA INFORMATIVA (YA NO ES COLA DE ESPERA, SINO HISTORIAL)
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.check, color: Colors.white)),
                      title: Text("Estudiante Atendido ${index + 1}"),
                      subtitle: Text("Hora: 0${8+index}:30 AM - Signos estables"),
                    ),
                  );
                },
              ),
            ),
            // Espacio para que el botón flotante no tape el último item
            const SizedBox(height: 60), 
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET SIMULADOR DE CÁMARA (FAKE SCANNER)
// ============================================================================
// En la app real, aquí usarías la librería 'mobile_scanner'
class _FakeCameraScanner extends StatelessWidget {
  const _FakeCameraScanner();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero, // Pantalla completa
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo de cámara
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: const Center(child: Text("CÁMARA ACTIVA...", style: TextStyle(color: Colors.white54))),
          ),
          
          // Cuadro de enfoque
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          // Botones de Simulación (Para probar en tu PC)
          Positioned(
            bottom: 50,
            child: Column(
              children: [
                const Text("Simular detección:", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'QR-STU-001'), // Devuelve código válido
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("QR VÁLIDO"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'INVALID-CODE'), // Devuelve error
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("QR ERRÓNEO"),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, null), // Cancela
                  child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET DIALOGO DE TRIAJE (CON DATOS PRE-CARGADOS)
// ============================================================================
class _TriageDialog extends StatefulWidget {
  final String patientName;
  final String patientId;
  final String faculty;

  const _TriageDialog({
    required this.patientName,
    required this.patientId,
    required this.faculty,
  });

  @override
  State<_TriageDialog> createState() => _TriageDialogState();
}

class _TriageDialogState extends State<_TriageDialog> {
  final _tempController = TextEditingController();
  final _presionController = TextEditingController();
  final _pesoController = TextEditingController();
  final _sintomasController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO CON DATOS DEL QR
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.teal, 
                    child: Icon(Icons.person, color: Colors.white)
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("${widget.faculty} • CI: ${widget.patientId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
              const Divider(height: 30),
              
              // SIGNOS VITALES
              const Text("Signos Vitales", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildInput(_tempController, "Temp (°C)", Icons.thermostat)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInput(_presionController, "P. Arterial", Icons.favorite)),
                ],
              ),
              const SizedBox(height: 10),
              _buildInput(_pesoController, "Peso (Kg)", Icons.monitor_weight),

              const SizedBox(height: 20),
              const Text("Pre-Diagnóstico / Motivo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 10),
              TextField(
                controller: _sintomasController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe los síntomas principales...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 30),
              
              // --- DECISIÓN ---
              const Text("Decisión de Triaje:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Atendido por Enfermería")));
                      },
                      icon: const Icon(Icons.medical_services_outlined, color: Colors.teal),
                      label: const Text("TRATAR AQUÍ", style: TextStyle(color: Colors.teal, fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Derivado al Doctor"), backgroundColor: Colors.blue));
                      },
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      label: const Text("DERIVAR DR.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      ),
    );
  }
}

// Widget simple para las tarjetas de estadísticas
class _InfoCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _InfoCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: color, width: 4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}