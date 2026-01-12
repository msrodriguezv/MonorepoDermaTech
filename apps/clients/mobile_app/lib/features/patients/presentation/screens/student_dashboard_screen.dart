import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/presentation/screens/login_screen.dart';

// --- FEATURE IMPORTS ---
import '../../data/datasources/patient_remote_data_source.dart';
import '../../data/models/patient_profile_model.dart';
import 'book_appointment_screen.dart'; 

/// Main Dashboard Screen for Students.
/// Converted to StatefulWidget to handle asynchronous data fetching.
class StudentDashboardScreen extends StatefulWidget {
  // We keep studentName as a fallback or initial data passed from login
  final String studentName;

  const StudentDashboardScreen({
    super.key, 
    required this.studentName,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  // --- STATE VARIABLES ---
  bool _isLoading = true;
  PatientProfileModel? _profile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// Fetches the real patient profile data from the backend.
  Future<void> _fetchProfileData() async {
    try {
      // Dependency Injection (Manual for now)
      final apiClient = ApiClient();
      final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);

      final profile = await patientDataSource.getPatientProfile();

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error cargando datos: $e";
          _isLoading = false;
        });
      }
      debugPrint("❌ [DASHBOARD] Error fetching profile: $e");
    }
  }

  /// Executes the Secure Logout Flow.
  Future<void> _handleLogout() async {
    const storage = FlutterSecureStorage();
    
    try {
      final token = await storage.read(key: 'accessToken');
      
      if (token != null) {
        final apiClient = ApiClient();
        final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
        
        // Invalidate token on server (Blacklist)
        await authDataSource.logout(token);
        debugPrint("🔍 [LOGOUT] Token invalidated on server.");
      }

    } catch (e) {
      debugPrint("⚠️ [LOGOUT ERROR] Server invalidation failed: $e");
    } finally {
      // Always clear local storage and navigate
      await storage.deleteAll();
      debugPrint("✅ [LOGOUT] Local storage cleared.");

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- LOADING STATE ---
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0A2342)),
        ),
      );
    }

    // --- ERROR STATE ---
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchProfileData,
                child: const Text("Reintentar"),
              ),
              TextButton(
                onPressed: _handleLogout, 
                child: const Text("Cerrar Sesión")
              )
            ],
          ),
        ),
      );
    }

    // --- SUCCESS STATE (Real Data) ---
    // Use the fetched profile data or fallbacks if strictly necessary
    final String displayFaculty = _profile?.faculty ?? "Facultad no registrada";
    final String displayCareer = _profile?.career ?? "Carrera no registrada";
    final String displaySemester = "${_profile?.currentSemester ?? 1}° Semestre";
    final String displayCode = _profile?.studentCode ?? "N/A";
    final String displayName = _profile?.fullName ?? widget.studentName;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("Mi Perfil - DermaTech", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2342), 
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Cerrar Sesión",
            onPressed: _handleLogout, 
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // 1. PROFILE CARD (REAL DATA)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2342), Color(0xFF00A8E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3), 
                    blurRadius: 10, 
                    offset: const Offset(0, 5)
                  )
                ],
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
                        Text(
                          "Hola, $displayName", 
                          style: const TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          )
                        ),
                        const SizedBox(height: 5),
                        Text(displayFaculty, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text("$displayCareer - $displaySemester", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2. QR ACCESS PASS (Using Real ID/Code)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text(
                    "TU PASE DE ACCESO", 
                    style: TextStyle(
                      color: Colors.grey, 
                      letterSpacing: 1.2, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 20),
                  // Visual QR Simulation
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
                    child: Text(
                      displayCode, // Displays generated code from Profile ID
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1, 
                        color: Color(0xFF0A2342)
                      )
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Presenta este código en Triaje", 
                    style: TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 12)
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // 3. UPCOMING APPOINTMENTS LIST (Still Mocked - Future Implementation)
            const Text(
              "Próximas Citas", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))
            ),
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
            
            // 4. BOOK NEW APPOINTMENT ACTION
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: const Text(
                "Agendar Nueva Cita", 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
              ),
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

// --- HELPER WIDGETS ---
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
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
            child: Text(
              status, 
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)
            ),
          )
        ],
      ),
    );
  }
}