import 'package:flutter/material.dart';
import '../api/api_service.dart';

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _apiService = ApiService();
  List<dynamic> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventsData = await _apiService.getEventos();
      setState(() {
        _events = eventsData;
      });
    } catch (e) {
      print('Error al cargar eventos: $e');
      
      // Si falla el backend, usar datos de ejemplo
      setState(() {
        _events = [
          {
            'id': 1,
            'nombre': 'Procesión de Semana Santa',
            'descripcion': 'Procesión tradicional por las calles del centro histórico',
            'fecha': '2025-04-13',
            'hora': '18:00',
            'ubicacion': 'Centro Histórico'
          },
          {
            'id': 2,
            'nombre': 'Reunión Mensual',
            'descripcion': 'Reunión mensual de la cofradía para tratar temas importantes',
            'fecha': '2025-08-20',
            'hora': '19:30',
            'ubicacion': 'Sala de Juntas'
          },
          {
            'id': 3,
            'nombre': 'Bendición de Túnicas',
            'descripcion': 'Ceremonia de bendición de las nuevas túnicas',
            'fecha': '2025-09-15',
            'hora': '11:00',
            'ubicacion': 'Iglesia Principal'
          }
        ];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mostrando eventos de ejemplo (backend no disponible)'),
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
        title: Text('Eventos'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay eventos disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return _buildEventCard(event);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(),
        backgroundColor: Colors.orange,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditEventDialog(event);
                    } else if (value == 'delete') {
                      _deleteEvent(event['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              event['descripcion'] ?? 'Sin descripción',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  event['fecha'] ?? 'Sin fecha',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (event['ubicacion'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['ubicacion'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _toggleAsistencia(event),
                  icon: Icon(Icons.check_circle, size: 16),
                  label: Text('Asistir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEventDetails(event),
                  icon: Icon(Icons.info, size: 16),
                  label: Text('Detalles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    final _nombreController = TextEditingController();
    final _descripcionController = TextEditingController();
    final _fechaController = TextEditingController();
    final _horaController = TextEditingController(text: '10:00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Evento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del evento',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _fechaController,
                decoration: InputDecoration(
                  labelText: 'Fecha (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _horaController,
                decoration: InputDecoration(
                  labelText: 'Hora (HH:MM)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nombreController.text.isNotEmpty) {
                try {
                  await ApiService.createEvento(
                    nombre: _nombreController.text,
                    descripcion: _descripcionController.text,
                    fecha: _fechaController.text,
                    hora: _horaController.text.isNotEmpty ? _horaController.text : '10:00',
                  );
                  Navigator.pop(context);
                  _loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Evento creado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al crear evento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Función de editar en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteEvent(int eventId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Función de eliminar en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _toggleAsistencia(Map<String, dynamic> event) async {
    try {
      // Aquí deberías tener el ID del usuario logueado
      final userId = 1; // Por ahora hardcodeado
      await ApiService.registrarAsistencia(
        eventoId: event['id'],
        cofradeId: userId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asistencia registrada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar asistencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['nombre'] ?? 'Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event['descripcion'] != null) ...[
              Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(event['descripcion']),
              SizedBox(height: 16),
            ],
            if (event['fecha'] != null) ...[
              Text('Fecha:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(event['fecha']),
              SizedBox(height: 16),
            ],
            if (event['ubicacion'] != null) ...[
              Text('Ubicación:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(event['ubicacion']),
              SizedBox(height: 16),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
