import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cofrade.dart';
import '../api/api_service.dart';

class CofradesScreen extends StatefulWidget {
  const CofradesScreen({super.key});

  @override
  _CofradesScreenState createState() => _CofradesScreenState();
}

class _CofradesScreenState extends State<CofradesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Cofrade> _cofrades = [];
  final _formKey = GlobalKey<FormState>();
  List<Cofrade> _filteredCofrades = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCofrades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCofrades() async {
    try {
      setState(() => _isLoading = true);
      final cofrades = await _apiService.getCofrades();
      setState(() {
        _cofrades = cofrades;
        _filteredCofrades = cofrades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar cofrades: $e');
    }
  }

  void _filterCofrades(String query) {
    setState(() {
      _filteredCofrades = _cofrades.where((cofrade) {
        final nombre = '${cofrade.nombre} ${cofrade.apellidos}'.toLowerCase();
        final searchQuery = query.toLowerCase();
        return nombre.contains(searchQuery);
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _confirmDelete(String nombre) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro que desea eliminar al cofrade "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteCofrade(Cofrade cofrade) async {
    if (!await _confirmDelete('${cofrade.nombre} ${cofrade.apellidos}')) return;

    try {
      await _apiService.deleteCofrade(cofrade.id);
      _showSuccess('Cofrade eliminado con éxito');
      _loadCofrades();
    } catch (e) {
      _showError('Error al eliminar cofrade: $e');
    }
  }

  void _showCofradePicture(String nombre, String? fotoUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nombre),
        content: fotoUrl != null && fotoUrl.isNotEmpty
            ? Image.network(
                fotoUrl,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.person,
                size: 100,
                color: Colors.grey,
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCofradiaDialog([Cofrade? cofrade]) {
    final bool isEditing = cofrade != null;
    final nombreController = TextEditingController(text: cofrade?.nombre ?? '');
    final apellidosController = TextEditingController(text: cofrade?.apellidos ?? '');
    final telefonoController = TextEditingController(text: cofrade?.telefono ?? '');
    final emailController = TextEditingController(text: cofrade?.email ?? '');
    final categoriaController = TextEditingController(text: cofrade?.categoria ?? 'Cofrade');
    final estadoController = TextEditingController(text: cofrade?.estado ?? 'Activo');
    final fechaAltaController = TextEditingController(text: cofrade?.fechaAlta ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Cofrade' : 'Nuevo Cofrade'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: apellidosController,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                DropdownButtonFormField<String>(
                  value: categoriaController.text,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: ['Cofrade', 'Hermano', 'Directivo']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => categoriaController.text = value ?? 'Cofrade',
                ),
                DropdownButtonFormField<String>(
                  value: estadoController.text,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: ['Activo', 'Inactivo']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => estadoController.text = value ?? 'Activo',
                ),
                TextFormField(
                  controller: fechaAltaController,
                  decoration: const InputDecoration(labelText: 'Fecha de Alta'),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      fechaAltaController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;

              final nuevoCofrade = Cofrade(
                id: cofrade?.id ?? '',
                nombre: nombreController.text,
                apellidos: apellidosController.text,
                telefono: telefonoController.text,
                email: emailController.text,
                categoria: categoriaController.text,
                estado: estadoController.text,
                fechaAlta: fechaAltaController.text,
              );

              try {
                if (isEditing) {
                  await _apiService.updateCofrade(nuevoCofrade.id, nuevoCofrade);
                  _showSuccess('Cofrade actualizado con éxito');
                } else {
                  await _apiService.createCofrade(nuevoCofrade);
                  _showSuccess('Cofrade creado con éxito');
                }
                Navigator.of(context).pop();
                _loadCofrades();
              } catch (e) {
                _showError(
                  isEditing
                      ? 'Error al actualizar cofrade: $e'
                      : 'Error al crear cofrade: $e',
                );
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cofrades'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar cofrades',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCofrades('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterCofrades,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredCofrades.length,
                    itemBuilder: (context, index) {
                      final cofrade = _filteredCofrades[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(cofrade.avatar),
                          ),
                          title: Text('${cofrade.nombre} ${cofrade.apellidos}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${cofrade.email}'),
                              Text('Teléfono: ${cofrade.telefono}'),
                              Text('${cofrade.categoria} - ${cofrade.estado}'),
                              Text('Fecha de alta: ${cofrade.fechaAlta}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showCofradiaDialog(cofrade);
                                  break;
                                case 'delete':
                                  _deleteCofrade(cofrade);
                                  break;
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCofradiaDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
