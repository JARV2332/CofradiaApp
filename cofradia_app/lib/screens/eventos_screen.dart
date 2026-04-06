import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento.dart';
import '../services/api_service.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Evento> _eventos = [];
  List<Evento> _filteredEventos = [];
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _lugarController = TextEditingController();
  DateTime _selectedFecha = DateTime.now();
  TimeOfDay _selectedHora = TimeOfDay.now();
  String? _selectedTipo;
  String? _selectedEstado;
  final _cupoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _lugarController.dispose();
    _cupoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final eventos = await _apiService.getEventos();
      setState(() {
        _eventos = eventos;
        _filteredEventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos: $e')),
        );
      }
    }
  }

  void _resetForm() {
    _nombreController.clear();
    _descripcionController.clear();
    _lugarController.clear();
    _selectedFecha = DateTime.now();
    _selectedHora = TimeOfDay.now();
    _selectedTipo = null;
    _selectedEstado = null;
    _cupoController.clear();
  }

  void _loadEventoToForm(Evento evento) {
    _nombreController.text = evento.nombre;
    _descripcionController.text = evento.descripcion;
    _lugarController.text = evento.lugar;
    _selectedFecha = DateFormat('yyyy-MM-dd').parse(evento.fecha);
    final horaParts = evento.hora.split(':');
    _selectedHora = TimeOfDay(hour: int.parse(horaParts[0]), minute: int.parse(horaParts[1]));
    _selectedTipo = evento.tipo;
    _selectedEstado = evento.estado;
    _cupoController.text = evento.cupo.toString();
  }

  Future<void> _showEventoDialog([Evento? evento]) async {
    if (evento != null) {
      _loadEventoToForm(evento);
    } else {
      _resetForm();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final dialogWidth = constraints.maxWidth < 560 ? constraints.maxWidth : 520.0;
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              title: Text(evento == null ? 'Nuevo Evento' : 'Editar Evento'),
              content: SizedBox(
                width: dialogWidth,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un nombre';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descripcionController,
                          decoration: const InputDecoration(labelText: 'Descripción'),
                          maxLines: 3,
                        ),
                        ListTile(
                          title: const Text('Fecha'),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedFecha)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: _selectedFecha,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2025),
                            );
                            if (picked != null) {
                              setState(() => _selectedFecha = picked);
                            }
                          },
                        ),
                        ListTile(
                          title: const Text('Hora'),
                          subtitle: Text(_selectedHora.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: dialogContext,
                              initialTime: _selectedHora,
                            );
                            if (picked != null) {
                              setState(() => _selectedHora = picked);
                            }
                          },
                        ),
                        TextFormField(
                          controller: _lugarController,
                          decoration: const InputDecoration(labelText: 'Lugar'),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedTipo,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const [
                            DropdownMenuItem(value: 'INTERNO', child: Text('Interno')),
                            DropdownMenuItem(value: 'EXTERNO', child: Text('Externo')),
                          ],
                          onChanged: (tipo) {
                            setState(() => _selectedTipo = tipo);
                          },
                          validator: (value) {
                            if (value == null) return 'Por favor seleccione un tipo';
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedEstado,
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: const [
                            DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                            DropdownMenuItem(value: 'CANCELADO', child: Text('Cancelado')),
                            DropdownMenuItem(value: 'COMPLETADO', child: Text('Completado')),
                          ],
                          onChanged: (estado) {
                            setState(() => _selectedEstado = estado);
                          },
                          validator: (value) {
                            if (value == null) return 'Por favor seleccione un estado';
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _cupoController,
                          decoration: const InputDecoration(labelText: 'Cupo'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un cupo';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Por favor ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final eventoNuevo = Evento(
                        id: evento?.id ?? '',
                        nombre: _nombreController.text,
                        descripcion: _descripcionController.text,
                        fecha: DateFormat('yyyy-MM-dd').format(_selectedFecha),
                        hora:
                            '${_selectedHora.hour.toString().padLeft(2, '0')}:${_selectedHora.minute.toString().padLeft(2, '0')}:00',
                        lugar: _lugarController.text,
                        tipo: _selectedTipo!,
                        estado: _selectedEstado!,
                        cupo: int.parse(_cupoController.text),
                      );

                      try {
                        if (evento == null) {
                          await _apiService.createEvento(eventoNuevo);
                        } else {
                          await _apiService.updateEvento(evento.id, eventoNuevo);
                        }
                        await _loadData();
                        if (mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              duration: const Duration(seconds: 8),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(evento == null ? 'Crear' : 'Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEvento(Evento evento) async {
    try {
      await _apiService.deleteEvento(evento.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el evento: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Evento evento) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de que desea eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteEvento(evento);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _filteredEventos = _eventos.where((evento) {
                    final searchLower = value.toLowerCase();
                    return evento.nombre.toLowerCase().contains(searchLower) ||
                           evento.descripcion.toLowerCase().contains(searchLower) ||
                           evento.lugar.toLowerCase().contains(searchLower) ||
                           evento.tipo.toLowerCase().contains(searchLower) ||
                           evento.estado.toLowerCase().contains(searchLower);
                  }).toList();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEventos.length,
              itemBuilder: (context, index) {
                final evento = _filteredEventos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(evento.nombre[0].toUpperCase()),
                    ),
                    title: Text(evento.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${evento.fecha} ${evento.hora}'),
                        Text('Lugar: ${evento.lugar}'),
                        Text('Tipo: ${evento.tipo}'),
                        Text('Estado: ${evento.estado}'),
                        Text('Cupo: ${evento.cupo}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEventoDialog(evento),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(evento),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventoDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
