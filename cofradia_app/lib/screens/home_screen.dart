import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  int _totalEventos = 0;
  int _totalCofrades = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar eventos y cofrades en paralelo
      final futures = await Future.wait([
        _apiService.getEventos(),
        _apiService.getCofrades(),
      ]);

      setState(() {
        _totalEventos = futures[0].length;
        _totalCofrades = futures[1].length;
      });
    } catch (e) {
      print('Error cargando datos del dashboard: $e');
      
      // Si falla el backend, usar datos de ejemplo
      setState(() {
        _totalEventos = 3; // Datos de ejemplo
        _totalCofrades = 12; // Datos de ejemplo
      });
      
      // Mostrar mensaje de que se usan datos de ejemplo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usando datos de ejemplo (backend no disponible)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cofradia App'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple.shade100],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gestiona tu cofradía fácilmente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Tarjetas de estadísticas
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildQuickAccessCard(
                        icon: Icons.event_available,
                        title: 'Total Eventos',
                        subtitle: _isLoading ? 'Cargando...' : '$_totalEventos eventos',
                        color: Colors.blue,
                        onTap: () {
                          // Mostrar mensaje de navegación
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navega a Eventos desde la barra inferior')),
                          );
                        },
                      ),
                      _buildQuickAccessCard(
                        icon: Icons.people_outline,
                        title: 'Total Cofrades',
                        subtitle: _isLoading ? 'Cargando...' : '$_totalCofrades miembros',
                        color: Colors.green,
                        onTap: () {
                          // Mostrar mensaje para usar la navegación inferior
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Usa la barra de navegación inferior para ir a Cofrades')),
                          );
                        },
                      ),
                      _buildQuickAccessCard(
                        icon: Icons.qr_code_scanner,
                        title: 'Escanear QR',
                        subtitle: 'Pasar asistencia',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickAccessCard(
                        icon: Icons.assessment,
                        title: 'Reportes',
                        subtitle: 'Ver estadísticas',
                        color: Colors.red,
                        onTap: () {
                          DefaultTabController.of(context)?.animateTo(3); // Cambiar a la pestaña de reportes
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Accesos rápidos adicionales
                  Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add_circle,
                          label: 'Nuevo Evento',
                          color: Colors.blueAccent,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ve a la pestaña Eventos para crear uno nuevo'),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.person_add,
                          label: 'Nuevo Cofrade',
                          color: Colors.greenAccent,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ve a la pestaña Cofrades para agregar uno nuevo'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
