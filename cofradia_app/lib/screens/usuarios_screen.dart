import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Usuario> _usuarios = [];
  List<Usuario> _filteredUsuarios = [];
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedRol;
  String? _selectedEstado;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final usuarios = await _apiService.getUsuarios();
      setState(() {
        _usuarios = usuarios;
        _filteredUsuarios = usuarios;
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
    _emailController.clear();
    _selectedRol = null;
    _selectedEstado = null;
  }

  void _loadUsuarioToForm(Usuario usuario) {
    _nombreController.text = usuario.nombre;
    _emailController.text = usuario.email;
    _selectedRol = usuario.rol;
    _selectedEstado = usuario.estado;
  }

  Future<void> _showUsuarioDialog([Usuario? usuario]) async {
    if (usuario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero el usuario debe registrarse en Login/Registro. Aquí solo se gestionan roles.'),
          ),
        );
      }
      return;
    }

    if (usuario != null) {
      _loadUsuarioToForm(usuario);
    } else {
      _resetForm();
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario == null ? 'Nuevo Usuario' : 'Editar Usuario'),
        content: Form(
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
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'User ID (UUID)'),
                  keyboardType: TextInputType.text,
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un user_id';
                    }
                    if (value.length < 10) {
                      return 'Ingrese un UUID válido';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedRol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'secretario', child: Text('Secretario')),
                    DropdownMenuItem(value: 'encargado', child: Text('Encargado')),
                  ],
                  onChanged: (rol) {
                    setState(() {
                      _selectedRol = rol;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Por favor seleccione un rol';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedEstado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                    DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
                    DropdownMenuItem(value: 'BLOQUEADO', child: Text('Bloqueado')),
                  ],
                  onChanged: (estado) {
                    setState(() {
                      _selectedEstado = estado;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Por favor seleccione un estado';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final usuarioNuevo = Usuario(
                  id: usuario?.id ?? '',
                  nombre: _nombreController.text,
                  email: _emailController.text,
                  rol: _selectedRol!,
                  estado: _selectedEstado!,
                  fechaIngreso: DateTime.now(),
                );

                try {
                  await _apiService.updateUsuario(usuario.id, usuarioNuevo);
                  await _loadData();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: Text(usuario == null ? 'Crear' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUsuario(Usuario usuario) async {
    try {
      await _apiService.deleteUsuario(usuario.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el usuario: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Usuario usuario) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de que desea eliminar este usuario?'),
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
      await _deleteUsuario(usuario);
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
        title: const Text('Usuarios'),
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
                  _filteredUsuarios = _usuarios.where((usuario) {
                    final searchLower = value.toLowerCase();
                    return usuario.nombre.toLowerCase().contains(searchLower) ||
                           usuario.email.toLowerCase().contains(searchLower) ||
                           usuario.rol.toLowerCase().contains(searchLower) ||
                           usuario.estado.toLowerCase().contains(searchLower);
                  }).toList();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsuarios.length,
              itemBuilder: (context, index) {
                final usuario = _filteredUsuarios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(usuario.nombre[0].toUpperCase()),
                    ),
                    title: Text(usuario.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${usuario.email}'),
                        Text('Rol: ${usuario.rol}'),
                        Text('Estado: ${usuario.estado}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUsuarioDialog(usuario),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(usuario),
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Los usuarios se crean con Registro. Desde aquí solo cambias roles.'),
            ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
