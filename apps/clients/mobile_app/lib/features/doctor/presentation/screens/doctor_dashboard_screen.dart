import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/presentation/screens/login_screen.dart';

// --- FEATURE IMPORTS ---
import 'medical_history_screen.dart'; 

/// **DoctorDashboardScreen**
///
/// The primary interface for the Medical Doctor role.
/// 
/// **Key Responsibilities:**
/// 1. Patient Queue Management & Triage Review.
/// 2. KPI Statistics (Consultations, Pending cases).
/// 3. Access to detailed Medical History editing.
/// 4. Secure Session Termination (Server-side Blacklisting).
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  
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
    // LAYOUT BUILDER FOR RESPONSIVE DESIGN
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint definition: Mobile < 800px
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.grey[50], // Professional neutral background
          
          // --- APP BAR ---
          appBar: AppBar(
            title: Text(
              isMobile ? "Medical Panel" : "Doctor Dashboard - DermaTech", 
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)
            ),
            backgroundColor: const Color(0xFF0D47A1), // Corporate Blue
            elevation: 2,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: "Sign Out",
                onPressed: _handleLogout, // Linked to robust logout logic
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

          // Use ListView to ensure scrollability on smaller screens
          body: ListView( 
            padding: const EdgeInsets.all(24.0),
            children: [
              
              // 1. STATISTICS SECTION (RESPONSIVE WRAP)
              Wrap(
                spacing: 20, 
                runSpacing: 20, 
                children: [
                  _StatCard(
                    title: "Total Patients", 
                    count: "125", 
                    color: Colors.blue, 
                    icon: Icons.people_alt_rounded,
                    width: isMobile ? constraints.maxWidth : 280 
                  ),
                  _StatCard(
                    title: "Consultations Today", 
                    count: "8", 
                    color: Colors.green, 
                    icon: Icons.calendar_today_rounded,
                    width: isMobile ? constraints.maxWidth : 280
                  ),
                  _StatCard(
                    title: "Pending Review", 
                    count: "3", 
                    color: Colors.orange, 
                    icon: Icons.pending_actions_rounded,
                    width: isMobile ? constraints.maxWidth : 280
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              // 2. PATIENT QUEUE HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Patients",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
                  ),
                  TextButton.icon(
                    onPressed: () {}, // Future Implementation: Open Filter Modal
                    icon: const Icon(Icons.filter_list_rounded, size: 20),
                    label: const Text("Filter List"),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // 3. PATIENT GRID (RESPONSIVE)
              GridView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), 
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4, 
                  childAspectRatio: isMobile ? 0.75 : 0.9, 
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: 6, // Mock Data Count
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
// HELPER WIDGETS
// ============================================================================

/// **_StatCard**
/// Displays Key Performance Indicators (KPIs) for the doctor.
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final MaterialColor color;
  final IconData icon;
  final double width; 

  const _StatCard({
    required this.title, 
    required this.count, 
    required this.color,
    required this.icon,
    required this.width
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08), 
            blurRadius: 12, 
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
              Text(
                title, 
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)
              ),
              const SizedBox(height: 8),
              Text(
                count, 
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))
              ),
            ],
          ),
          Icon(icon, size: 40, color: color.withOpacity(0.2)),
        ],
      ),
    );
  }
}

/// **_PatientCard**
/// Represents a single patient item in the dashboard grid.
/// Contains quick actions to view profile or edit medical history.
class _PatientCard extends StatelessWidget {
  const _PatientCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Patient Avatar
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE3F2FD), 
              child: Icon(Icons.person, color: Color(0xFF0D47A1), size: 30),
            ),
            const SizedBox(height: 12),
            
            // Patient Info
            const Text(
              "Carlos Pérez", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A2342)),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text("ID: 1712345678", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            
            const SizedBox(height: 12),
            
            // Status Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Pending", 
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)
              ),
            ),
            
            const Spacer(),
            const Divider(), 
            
            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Action 1: Quick View Profile
                InkWell(
                  onTap: () {}, // Future: Open Quick Profile Modal
                  borderRadius: BorderRadius.circular(50),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.visibility_outlined, color: Colors.grey, size: 22),
                  ),
                ),
                
                // Action 2: Medical History (Primary Action)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
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
                      minimumSize: const Size(0, 32), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "History", 
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)
                    ),
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