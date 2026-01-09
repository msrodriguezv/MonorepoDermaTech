import 'package:flutter/material.dart';
import '../widgets/user_form_dialog.dart'; // Asegúrate de que este archivo existe en la carpeta widgets

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard},
    {'title': 'Doctores', 'icon': Icons.medical_services},
    {'title': 'Enfermeros', 'icon': Icons.local_hospital},
    {'title': 'Pacientes', 'icon': Icons.people},
    {'title': 'Configuración', 'icon': Icons.settings},
  ];

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // RESPONSIVE: Consideramos móvil si es menor a 800px
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7FA),
          
          // --- APP BAR (SOLO EN MÓVIL) ---
          appBar: isMobile
              ? AppBar(
                  backgroundColor: const Color(0xFF0A2342),
                  title: const Text("Admin DermaTech", style: TextStyle(color: Colors.white)),
                  iconTheme: const IconThemeData(color: Colors.white),
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                )
              : null,

          // --- DRAWER (MENÚ LATERAL MÓVIL) ---
          drawer: isMobile
              ? Drawer(
                  child: _SidebarContent(
                    menuItems: _menuItems,
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemSelected,
                  ),
                )
              : null,

          // --- CUERPO PRINCIPAL ---
          body: Row(
            children: [
              // 1. SIDEBAR FIJO (SOLO EN ESCRITORIO)
              if (!isMobile)
                SizedBox(
                  width: 260,
                  child: Container(
                    color: const Color(0xFF0A2342),
                    child: _SidebarContent(
                      menuItems: _menuItems,
                      selectedIndex: _selectedIndex,
                      onItemSelected: _onItemSelected,
                    ),
                  ),
                ),

              // 2. CONTENIDO PRINCIPAL
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildContent(isMobile),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Router interno de vistas
  Widget _buildContent(bool isMobile) {
    switch (_selectedIndex) {
      case 0:
        return _DashboardOverview(isMobile: isMobile);
      case 1:
        return _UserCrudView(roleTitle: "Doctores", roleColor: Colors.blue, isMobile: isMobile);
      case 2:
        return _UserCrudView(roleTitle: "Enfermeros", roleColor: Colors.teal, isMobile: isMobile);
      case 3:
        return _UserCrudView(roleTitle: "Pacientes", roleColor: Colors.green, isMobile: isMobile);
      default:
        return const Center(child: Text("Configuración en construcción"));
    }
  }
}

// ============================================================================
// WIDGET SIDEBAR (MENÚ LATERAL)
// ============================================================================
class _SidebarContent extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const _SidebarContent({
    required this.menuItems,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A2342),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  "ADMINISTRADOR",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text("DermaTech UCE", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(item['icon'], color: isSelected ? Colors.white : Colors.white70),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => onItemSelected(index),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET 1: DASHBOARD OVERVIEW (ESTADÍSTICAS)
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
          const Text("Panel General", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
          const SizedBox(height: 10),
          const Text("Resumen de actividad.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _StatCard(title: "Doctores", count: "12", icon: Icons.medical_services, color: Colors.blue, width: isMobile ? double.infinity : 200),
              _StatCard(title: "Enfermeros", count: "24", icon: Icons.local_hospital, color: Colors.teal, width: isMobile ? double.infinity : 200),
              _StatCard(title: "Pacientes", count: "1,250", icon: Icons.people, color: Colors.green, width: isMobile ? double.infinity : 200),
              _StatCard(title: "Citas Hoy", count: "45", icon: Icons.calendar_today, color: Colors.orange, width: isMobile ? double.infinity : 200),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET 2: CRUD REUTILIZABLE (TABLA DE GESTIÓN MEJORADA)
// ============================================================================
class _UserCrudView extends StatelessWidget {
  final String roleTitle;
  final Color roleColor;
  final bool isMobile;

  const _UserCrudView({
    super.key,
    required this.roleTitle, 
    required this.roleColor, 
    required this.isMobile
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ENCABEZADO RESPONSIVE
        isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Gestión de $roleTitle", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
              const SizedBox(height: 10),
              _buildAddButton(context, isFullWidth: true),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Gestión de $roleTitle", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
                  Text("Administre los registros de $roleTitle.", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              _buildAddButton(context, isFullWidth: false),
            ],
          ),
        
        const SizedBox(height: 20),

        // --- TABLA AJUSTADA PARA LLENAR SIN DESBORDAR ---
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ancho disponible
                  final double minWidth = constraints.maxWidth;
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      // Esto asegura que las líneas divisorias lleguen hasta el final
                      // pero NO fuerza a las columnas a separarse excesivamente
                      constraints: BoxConstraints(minWidth: minWidth),
                      child: DataTable(
                        // AJUSTE CLAVE AQUÍ:
                        // Usamos un espaciado fijo y seguro. 
                        // 20px en móvil (compacto), 40px en escritorio (aireado pero sin desbordar)
                        columnSpacing: isMobile ? 20 : 40, 
                        horizontalMargin: 30, // Margen a los costados
                        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                        columns: const [
                          DataColumn(label: Text("Nombre Completo", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Estado", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: List.generate(5, (index) => DataRow(
                          cells: [
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(backgroundColor: roleColor.withOpacity(0.1), child: Text("U$index", style: TextStyle(color: roleColor))),
                                const SizedBox(width: 10),
                                Text("Usuario Ejemplo $index"),
                              ],
                            )),
                            DataCell(Text("usuario$index@dermatech.com")),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: const Text("Activo", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () {}),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () {}),
                              ],
                            )),
                          ],
                        )),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, {required bool isFullWidth}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () {
          // Llama al Formulario Modal Reutilizable
          showDialog(
            context: context,
            builder: (_) => UserFormDialog(
              roleTitle: roleTitle,
              roleColor: roleColor,
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Nuevo ${roleTitle.substring(0, roleTitle.length - 1)}", style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: roleColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}