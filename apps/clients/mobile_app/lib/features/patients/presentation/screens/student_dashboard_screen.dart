import 'package:flutter/material.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/presentation/screens/login_screen.dart';

// --- FEATURE IMPORTS ---
import '../../data/datasources/patient_remote_data_source.dart';
import '../../data/models/patient_profile_model.dart';
import 'book_appointment_screen.dart'; 

/// **StudentDashboardScreen**
class StudentDashboardScreen extends StatefulWidget {
  // Fallback name passed from the Login flow if API fails or while loading.
  final String studentName;
  
  // ❌ ELIMINADO: final _storage = StorageService(); de aquí para respetar el const constructor.

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

  // ✅ AGREGADO: La instancia se crea aquí, dentro del Estado.
  final _storage = StorageService(); 

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// **_fetchProfileData**
  Future<void> _fetchProfileData() async {
    try {
      final apiClient = ApiClient();
      final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);

      final profile = await patientDataSource.getPatientProfile();

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading data. Please try again.";
          _isLoading = false;
        });
      }
      debugPrint("❌ [DASHBOARD] Profile fetch failed: $error");
    }
  }

  /// **_handleLogout**
  Future<void> _handleLogout() async {
    try {
      // ✅ Ahora _storage sí es accesible aquí
      final token = await _storage.read(key: 'accessToken');
      
      if (token != null) {
        final apiClient = ApiClient();
        final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
        await authDataSource.logout(token);
      }
    } catch (e) {
      debugPrint("⚠️ [LOGOUT] Server invalidation failed: $e");
    } finally {
      // ✅ Local Cleanup
      await _storage.deleteAll();
      debugPrint("✅ [LOGOUT] Local session cleared.");

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
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
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2342)),
          ),
        ),
      );
    }

    // --- ERROR STATE ---
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Unable to load dashboard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 30),
                OutlinedButton(
                  onPressed: _fetchProfileData,
                  child: const Text("Retry Connection"),
                ),
                TextButton(
                  onPressed: _handleLogout, 
                  child: const Text("Logout", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
        ),
      );
    }

    // --- SUCCESS STATE (Render Data) ---
    final String displayFaculty = _profile?.faculty ?? "Facultad no registrada";
    final String displayCareer = _profile?.career ?? "Carrera no registrada";
    final String displaySemester = "${_profile?.currentSemester ?? 1}° Semestre";
    final String displayCode = _profile?.studentCode ?? "N/A";
    final String displayName = _profile?.fullName ?? widget.studentName;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("Mi Perfil - DermaTech", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF0A2342), 
        elevation: 0,
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: "Cerrar Sesión",
            onPressed: _handleLogout, 
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // 1. PROFILE CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2342), Color(0xFF00A8E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A8E8).withOpacity(0.3), 
                    blurRadius: 15, 
                    offset: const Offset(0, 8)
                  )
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 36, color: Color(0xFF0A2342)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, $displayName", 
                          style: const TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: 0.5,
                          )
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayFaculty, 
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$displayCareer - $displaySemester", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. QR ACCESS PASS
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "TU PASE DE ACCESO", 
                    style: TextStyle(
                      color: Colors.grey, 
                      letterSpacing: 1.5, 
                      fontSize: 11, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Visualization
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0A2342), size: 24),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA), 
                      borderRadius: BorderRadius.circular(30)
                    ),
                    child: Text(
                      displayCode, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.2, 
                        color: Color(0xFF0A2342),
                        fontSize: 16
                      )
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Presenta este código en Triaje", 
                    style: TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.w600, fontSize: 13)
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),

            // 3. APPOINTMENTS SECTION
            const Text(
              "Próximas Citas", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))
            ),
            const SizedBox(height: 15),
            
            // Mock Data
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
              status: "Pendiente",
              doctor: "Por asignar",
              color: Colors.orange,
            ),

            const SizedBox(height: 25),
            
            // 4. ACTION BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                  );
                },
                icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Agendar Nueva Cita", 
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: const Color(0xFF00A8E8).withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- HELPER COMPONENTS ---

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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A2342))
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
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
              color: color.withOpacity(0.08),
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