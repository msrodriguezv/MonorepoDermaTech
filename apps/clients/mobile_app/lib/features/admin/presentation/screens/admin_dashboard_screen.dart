import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/presentation/screens/login_screen.dart';

// --- WIDGET IMPORTS ---
// Ensure this widget exists in your project structure
import '../widgets/user_form_dialog.dart'; 

/// **AdminDashboardScreen**
///
/// The primary interface for the Administrator role.
/// 
/// **Key Responsibilities:**
/// 1. System-wide Key Performance Indicators (KPIs).
/// 2. CRUD Operations for medical staff and patients.
/// 3. Secure Session Termination (Server-side Blacklisting).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // --- STATE VARIABLES ---
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- NAVIGATION CONFIGURATION ---
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'Doctors', 'icon': Icons.medical_services_outlined},
    {'title': 'Nurses', 'icon': Icons.local_hospital_outlined},
    {'title': 'Patients', 'icon': Icons.people_outline},
    {'title': 'Settings', 'icon': Icons.settings_outlined},
  ];

  /// Handles sidebar navigation updates.
  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    // Close drawer automatically on mobile devices
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsiveness Breakpoint: Mobile < 800px
        final bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7FA), // Neutral professional background
          
          // --- MOBILE APP BAR ---
          appBar: isMobile
              ? AppBar(
                  backgroundColor: const Color(0xFF0A2342),
                  title: const Text("Admin Console", style: TextStyle(color: Colors.white)),
                  iconTheme: const IconThemeData(color: Colors.white),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                )
              : null,

          // --- MOBILE DRAWER ---
          drawer: isMobile
              ? Drawer(
                  child: _Sidebar(
                    menuItems: _menuItems,
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemSelected,
                    onLogout: _handleLogout,
                  ),
                )
              : null,

          // --- DESKTOP LAYOUT ---
          body: Row(
            children: [
              // Persistent Sidebar for Desktop
              if (!isMobile)
                SizedBox(
                  width: 260,
                  child: _Sidebar(
                    menuItems: _menuItems,
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemSelected,
                    onLogout: _handleLogout,
                  ),
                ),

              // Main Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _ContentRouter(
                    selectedIndex: _selectedIndex,
                    isMobile: isMobile,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// COMPONENT: SIDEBAR NAVIGATION
// ============================================================================

class _Sidebar extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.menuItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A2342), // Corporate Navy Blue
      child: Column(
        children: [
          // Branding Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  "ADMIN PORTAL",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.5,
                    fontSize: 14
                  ),
                ),
                Text(
                  "DermaTech Enterprise", 
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'], 
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => onItemSelected(index),
                    dense: true,
                  ),
                );
              },
            ),
          ),
          
          // Logout Action
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              title: const Text(
                "Sign Out", 
                style: TextStyle(color: Colors.white, fontSize: 14)
              ),
              onTap: onLogout,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENT: CONTENT ROUTER
// ============================================================================

class _ContentRouter extends StatelessWidget {
  final int selectedIndex;
  final bool isMobile;

  const _ContentRouter({required this.selectedIndex, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    // Dynamic routing based on sidebar selection
    switch (selectedIndex) {
      case 0:
        return _DashboardOverview(isMobile: isMobile);
      case 1:
        return _UserManagementView(roleTitle: "Doctors", roleColor: Colors.blue, isMobile: isMobile);
      case 2:
        return _UserManagementView(roleTitle: "Nurses", roleColor: Colors.teal, isMobile: isMobile);
      case 3:
        return _UserManagementView(roleTitle: "Patients", roleColor: Colors.green, isMobile: isMobile);
      default:
        return const Center(
          child: Text(
            "Configuration module unavailable.",
            style: TextStyle(color: Colors.grey),
          ),
        );
    }
  }
}

// ============================================================================
// VIEW: DASHBOARD OVERVIEW
// ============================================================================

class _DashboardOverview extends StatelessWidget {
  final bool isMobile;
  const _DashboardOverview({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Overview", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))
          ),
          const SizedBox(height: 8),
          Text("Metrics and activity summary.", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 32),

          // KPI Cards Grid
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _KpiCard(
                title: "Doctors", 
                count: "12", 
                color: Colors.blue, 
                width: isMobile ? double.infinity : 220
              ),
              _KpiCard(
                title: "Nurses", 
                count: "24", 
                color: Colors.teal, 
                width: isMobile ? double.infinity : 220
              ),
              _KpiCard(
                title: "Patients", 
                count: "1,250", 
                color: Colors.green, 
                width: isMobile ? double.infinity : 220
              ),
              _KpiCard(
                title: "Appointments", 
                count: "45", 
                color: Colors.orange, 
                width: isMobile ? double.infinity : 220
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final double width;

  const _KpiCard({
    required this.title,
    required this.count,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================================
// VIEW: USER MANAGEMENT CRUD
// ============================================================================

class _UserManagementView extends StatelessWidget {
  final String roleTitle;
  final Color roleColor;
  final bool isMobile;

  const _UserManagementView({
    required this.roleTitle, 
    required this.roleColor, 
    required this.isMobile
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Action Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$roleTitle Management", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("Manage registered accounts.", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => UserFormDialog(roleTitle: roleTitle, roleColor: roleColor),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: Text("Add $roleTitle", style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),

        // Data Table
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                  columnSpacing: 40,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn(label: Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(5, (index) => DataRow(
                    cells: [
                      DataCell(Text("User Example $index", style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text("user$index@dermatech.com")),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text("Active", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () {}),
                        ],
                      )),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}