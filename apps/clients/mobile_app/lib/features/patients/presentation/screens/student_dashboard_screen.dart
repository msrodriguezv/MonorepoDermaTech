import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/patient_remote_data_source.dart';
import '../../../appointments/data/datasources/appointment_remote_data_source.dart';
import '../../data/models/patient_profile_model.dart';
import '../../../appointments/data/models/appointment_model.dart';
import 'package:go_router/go_router.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isLoading = true;
  PatientProfileModel? _profile;
  List<AppointmentModel> _appointments = [];
  String? _errorMessage;
  final _storage = StorageService();
  late AppointmentRemoteDataSourceImpl _appointmentDataSource;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final apiClient = ApiClient();
      final patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
      _appointmentDataSource = AppointmentRemoteDataSourceImpl(apiClient: apiClient);

      final results = await Future.wait([
        patientDataSource.getPatientProfile(),
        _appointmentDataSource.getMyAppointments(),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as PatientProfileModel;
          _appointments = results[1] as List<AppointmentModel>;
          // Ordenar por fecha descendente (más reciente primero)
          _appointments.sort((a, b) => b.startTime.compareTo(a.startTime));
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = "No pudimos cargar tu información. Revisa tu conexión.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        final apiClient = ApiClient();
        final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
        await authDataSource.logout(token);
      }
    } catch (_) {
    } finally {
      await _storage.deleteAll();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      Navigator.pop(context); // Cerrar modal detalle
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _appointmentDataSource.cancelAppointment(appointmentId);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cita cancelada correctamente"), backgroundColor: Colors.green),
        );
        // Recargar datos
        setState(() => _isLoading = true);
        _fetchDashboardData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cancelar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Detalle de Cita",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
              ),
              const SizedBox(height: 20),
              _DetailRow(icon: Icons.person, label: "Doctor", value: appointment.doctorName),
              _DetailRow(icon: Icons.medical_services, label: "Especialidad", value: appointment.doctorSpecialty),
              if (appointment.doctorLicense.isNotEmpty)
                _DetailRow(icon: Icons.badge, label: "Licencia", value: appointment.doctorLicense),
              const Divider(height: 30),
              _DetailRow(icon: Icons.calendar_today, label: "Fecha", value: appointment.formattedDate),
              _DetailRow(icon: Icons.access_time, label: "Horario", value: appointment.formattedTimeRange),
              const Divider(height: 30),
              const Text("Síntomas registrados:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(appointment.symptoms, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 30),
              
              // Botón de cancelar solo si la cita es futura y no está cancelada/completada
              if (appointment.status != 'CANCELLED' && appointment.status != 'COMPLETED')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(appointment.id),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text("Cancelar Cita", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmCancel(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Cancelar Cita?"),
        content: const Text("Esta acción no se puede deshacer. ¿Estás seguro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(id);
            },
            child: const Text("Sí, Cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2342)))),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _fetchDashboardData();
                  },
                  child: const Text("Reintentar"))
            ],
          ),
        ),
      );
    }

    final displayFaculty = _profile?.faculty ?? "Facultad no registrada";
    final displayCareer = _profile?.career ?? "Carrera no registrada";
    final displaySemester = _profile?.currentSemester != null
        ? "${_profile!.currentSemester}° Semestre"
        : "Semestre no registrado";
    final displayCode = _profile?.studentCode ?? "N/A";
    final displayName = _profile?.fullName ?? "Estudiante";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mi Perfil - DermaTech",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF0A2342),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(displayName, displayFaculty, displayCareer, displaySemester),
            const SizedBox(height: 30),
            _buildQrCard(displayCode),
            const SizedBox(height: 35),
            const Text(
              "Mis Citas Médicas",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2342)),
            ),
            const SizedBox(height: 15),
            if (_appointments.isEmpty)
              _buildEmptyState()
            else
              ..._appointments.map((appt) => GestureDetector(
                onTap: () => _showAppointmentDetails(appt),
                child: _AppointmentCard(appointment: appt),
              )),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/profile/book');
                  setState(() => _isLoading = true);
                  _fetchDashboardData();
                },
                icon: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 20),
                label: const Text("Agendar Nueva Cita",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ... (Los métodos _buildProfileHeader, _buildQrCard y _buildEmptyState se mantienen igual)
  Widget _buildProfileHeader(String name, String faculty, String career, String semester) {
    return Container(
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
              offset: const Offset(0, 8))
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
                Text("Hola, $name",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(faculty,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 12)),
                const SizedBox(height: 4),
                Text("$career - $semester",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(String studentCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Text("TU PASE DE ACCESO",
              style: TextStyle(
                  color: Colors.grey,
                  letterSpacing: 1.5,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: studentCode,
              version: QrVersions.auto,
              size: 160.0,
              foregroundColor: const Color(0xFF0A2342),
              errorStateBuilder: (cxt, err) {
                return const Center(child: Text("Sin código", textAlign: TextAlign.center));
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(30)),
            child: Text(studentCode,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF0A2342),
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Text("No tienes citas próximas.",
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A2342), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (appointment.status.toUpperCase()) {
      case 'SCHEDULED':
      case 'CONFIRMED':
        statusColor = Colors.blue;
        statusText = "Programada";
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = "Pendiente";
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusText = "Finalizada";
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = "Cancelada";
        break;
      default:
        statusColor = Colors.grey;
        statusText = appointment.status;
    }

    // Usamos los getters del nuevo AppointmentModel
    final formattedDate = appointment.formattedDate;
    final formattedTime = appointment.formattedTimeRange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0A2342))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(formattedTime,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(appointment.doctorName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(appointment.doctorSpecialty, // Mostrar especialidad
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          )
        ],
      ),
    );
  }
}