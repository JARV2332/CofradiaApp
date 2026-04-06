import 'package:flutter/material.dart';
import 'asistencias_screen.dart';
import 'eventos_screen.dart';
import 'cofrades_screen.dart';
import 'usuarios_screen.dart';
import 'reportes_screen.dart';
import 'qr_scanner_screen.dart';
import 'role_management_screen.dart';
import '../api/auth_service.dart';
import 'login_screen.dart';
import '../theme/cofradia_theme.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const AsistenciasScreen(),
    const EventosScreen(),
    const CofradesScreen(),
    const UsuariosScreen(),
    const ReportesScreen(),
  ];
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CofradiaTheme.blancoCofradia,
                shape: BoxShape.circle,
                border: Border.all(color: CofradiaTheme.amarilloCofradia, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Cofradía App'),
          ],
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: CofradiaTheme.gradientePrincipal,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner,
              color: CofradiaTheme.amarilloCofradia,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
            },
            tooltip: 'Escanear QR',
          ),
          IconButton(
            icon: const Icon(Icons.shield),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoleManagementScreen(),
                ),
              );
            },
            tooltip: 'Gestión de roles',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        elevation: 8,
        backgroundColor: CofradiaTheme.blancoCofradia,
        indicatorColor: CofradiaTheme.amarilloCofradia.withOpacity(0.3),
        surfaceTintColor: CofradiaTheme.azulCofradia,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined, color: CofradiaTheme.azulCofradia),
            selectedIcon: Icon(Icons.event_available, color: CofradiaTheme.azulCofradia),
            label: 'Asistencias',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined, color: CofradiaTheme.azulCofradia),
            selectedIcon: Icon(Icons.event, color: CofradiaTheme.azulCofradia),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: CofradiaTheme.rojoCofradia),
            selectedIcon: Icon(Icons.people, color: CofradiaTheme.rojoCofradia),
            label: 'Cofrades',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined, color: CofradiaTheme.azulCofradia),
            selectedIcon: Icon(Icons.admin_panel_settings, color: CofradiaTheme.azulCofradia),
            label: 'Usuarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, color: CofradiaTheme.azulCofradia),
            selectedIcon: Icon(Icons.analytics, color: CofradiaTheme.azulCofradia),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
