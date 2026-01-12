import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/presentation/screens/login_screen.dart';

/// **NurseDashboardScreen**
///
/// Main interface for the Nursing Staff role.
/// 
/// **Key Features:**
/// 1. Patient Triage Management.
/// 2. QR Code Scanning for patient identification.
/// 3. Vital Signs Recording & Validation.
/// 4. Referral System (Local Treatment vs. Doctor Referral).
class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  // --- MOCK DATABASE ---
  // Simulates a backend response when scanning a QR code.
  // In production, this implies an API call: 'GET /patients/{id}'.
  final Map<String, dynamic> _studentDatabase = {
    'QR-STU-001': {'name': 'Carlos Pérez', 'faculty': 'Engineering', 'id': '1712345678'},
    'QR-STU-002': {'name': 'Ana Gómez', 'faculty': 'Medicine', 'id': '1723456789'},
    'QR-STU-003': {'name': 'Luis Toapanta', 'faculty': 'Arts', 'id': '1734567890'},
  };

  /// **_startScanProcess**
  /// Initiates the camera scanning workflow.
  /// 
  /// **Flow:**
  /// 1. Opens the Camera UI (Mocked for emulator).
  /// 2. Captures scanned code.
  /// 3. Validates code against local/remote database.
  /// 4. Triggers the Triage Dialog upon success.
  void _startScanProcess() async {
    // 1. Open Camera (Mock Implementation)
    final String? scannedCode = await showDialog<String>(
      context: context,
      builder: (_) => const _FakeCameraScanner(),
    );

    // 2. Validation Logic
    if (scannedCode != null && mounted) {
      if (_studentDatabase.containsKey(scannedCode)) {
        final student = _studentDatabase[scannedCode];
        
        // Success Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Identified: ${student['name']}"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 3. Open Triage Workflow
        showDialog(
          context: context,
          barrierDismissible: false, // Force a triage decision
          builder: (_) => _TriageDialog(
            patientName: student['name'],
            patientId: student['id'],
            faculty: student['faculty'],
          ),
        );
      } else {
        // Error Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Invalid QR Code or Patient Not Found."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// **_handleLogout**
  /// Executes the robust logout workflow ensuring server and client synchronization.
  /// 
  /// **Flow:**
  /// 1. Retrieve the current Access Token from Secure Storage.
  /// 2. API Call: Request backend to blacklist the token (Redis).
  /// 3. Local Cleanup: Delete all persisted session data.
  /// 4. Navigation: Redirect to Login and wipe history.
  Future<void> _handleLogout() async {
    const storage = FlutterSecureStorage();
    
    try {
      // 1. Retrieve Token
      final token = await storage.read(key: 'accessToken');
      
      if (token != null) {
        // 2. Initialize Dependencies
        final apiClient = ApiClient();
        final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
        
        // 3. Server Invalidation (Redis Blacklist)
        await authDataSource.logout(token);
        debugPrint("✅ [LOGOUT] Token invalidated on server.");
      }
    } catch (e) {
      // Fallback: Proceed with local logout even if server connection fails.
      debugPrint("⚠️ [LOGOUT] Server invalidation warning: $e");
    } finally {
      // 4. Local Cleanup (Critical)
      await storage.deleteAll();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Predicate to remove all previous routes
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("Nursing Station - Triage", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.teal[700],
        elevation: 2,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: "Sign Out",
            onPressed: _handleLogout, // Linked to robust logout logic
          )
        ],
      ),
      
      // --- FAB (SCANNER TRIGGER) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScanProcess,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
        label: const Text(
          "SCAN PATIENT QR", 
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)
        ),
        elevation: 4,
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. STATISTICS DASHBOARD
            Row(
              children: [
                _InfoCard(
                  title: "Patients Today", 
                  count: "12", 
                  color: Colors.teal,
                  icon: Icons.people_alt_rounded
                ),
                const SizedBox(width: 16),
                _InfoCard(
                  title: "Referred to Dr.", 
                  count: "4", 
                  color: Colors.blue,
                  icon: Icons.medical_services_rounded
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 2. HISTORY SECTION TITLE
            const Text(
              "Recent Activity", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))
            ),
            const SizedBox(height: 4),
            Text(
              "Patients evaluated during this shift.", 
              style: TextStyle(color: Colors.grey[600], fontSize: 13)
            ),
            const SizedBox(height: 16),

            // 3. ACTIVITY LIST
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2)
                        )
                      ]
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.withOpacity(0.1),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 20)
                      ),
                      title: Text(
                        "Student Treated ${index + 1}",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("Time: 0${8+index}:30 AM • Vitals Stable"),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            // Padding to prevent FAB from overlapping the last item
            const SizedBox(height: 70), 
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

/// **_InfoCard**
/// Reusable widget for statistics display.
class _InfoCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _InfoCard({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
                Icon(icon, color: color.withOpacity(0.2), size: 30)
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          ]
        ),
      ),
    );
  }
}

/// **_FakeCameraScanner**
/// Simulates the Camera Interface for development/emulator purposes.
class _FakeCameraScanner extends StatelessWidget {
  const _FakeCameraScanner();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero, // Full Screen Immersive
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera Feed Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: const Center(
              child: Text(
                "CAMERA ACTIVE...", 
                style: TextStyle(color: Colors.white54, letterSpacing: 2)
              )
            ),
          ),
          
          // Focus Box Overlay
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Corner Accents (Visual Flair)
                Positioned(top: 0, left: 0, child: _Corner(color: Colors.redAccent)),
                Positioned(top: 0, right: 0, child: _Corner(color: Colors.redAccent)),
                Positioned(bottom: 0, left: 0, child: _Corner(color: Colors.redAccent)),
                Positioned(bottom: 0, right: 0, child: _Corner(color: Colors.redAccent)),
              ],
            ),
          ),

          // Simulation Controls (Dev Only)
          Positioned(
            bottom: 60,
            child: Column(
              children: [
                const Text("DEV SIMULATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'QR-STU-001'), // Return Valid
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("VALID QR"),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'INVALID-CODE'), // Return Invalid
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text("INVALID QR"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, null), // Cancel
                  child: const Text("Cancel Scan", style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  const _Corner({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 20, height: 20, color: color);
  }
}

/// **_TriageDialog**
/// Modal form for entering Vital Signs and Triage Decisions.
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
  final _bpController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500, // Fixed width for Tablet/Desktop consistency
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal, 
                    child: Icon(Icons.person, color: Colors.white, size: 28)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("${widget.faculty} • ID: ${widget.patientId}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
              const Divider(height: 40),
              
              // VITALS SECTION
              const Text("Vital Signs", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 15)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInput(_tempController, "Temp (°C)", Icons.thermostat)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInput(_bpController, "BP (mmHg)", Icons.favorite_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput(_weightController, "Weight (Kg)", Icons.monitor_weight_rounded),

              const SizedBox(height: 24),
              
              // SYMPTOMS SECTION
              const Text("Chief Complaint / Symptoms", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: _symptomsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe primary symptoms...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 32),
              
              // ACTION BUTTONS
              const Text("Triage Decision:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing: Local Treatment")));
                      },
                      icon: const Icon(Icons.medical_services_outlined, color: Colors.teal),
                      label: const Text("TREAT LOCALLY", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing: Referred to Doctor")));
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      label: const Text("REFER TO DR.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800], 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
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
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}