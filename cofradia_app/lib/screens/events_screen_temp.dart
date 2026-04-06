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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar eventos: $e'),
          backgroundColor: Colors.red,
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
                  label: Text('Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
    final _ubicacionController = TextEditingController();

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
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
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
                    hora: '',
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
    final _nombreController = TextEditingController(text: event['nombre']);
    final _descripcionController = TextEditingController(text: event['descripcion']);
    final _fechaController = TextEditingController(text: event['fecha']);
    final _ubicacionController = TextEditingController(text: event['ubicacion']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Evento'),
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
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
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
                  await ApiService.updateEvento(
                    id: event['id'],
                    nombre: _nombreController.text,
                    descripcion: _descripcionController.text,
                    fecha: _fechaController.text,
                    hora: '',
                  );
                  Navigator.pop(context);
                  _loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Evento actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar evento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int eventId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.deleteEvento(eventId);
                Navigator.pop(context);
                _loadEvents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Evento eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar evento: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAsistencia(Map<String, dynamic> event) async {
    try {
      // Aquí deberías tener el ID del usuario logueado
      final userId = 1; // Por ahora hardcodeado
  await ApiService.registrarAsistencia(eventoId: event['id'], cofradeId: userId);
      
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
