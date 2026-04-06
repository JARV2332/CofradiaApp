import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final _targetUserIdController = TextEditingController();
  String? _currentRole;
  bool _isLoading = true;

  final List<String> _roles = const [
    'super_admin',
    'admin',
    'secretario',
    'encargado',
  ];

  String _selectedRole = 'encargado';

  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
  }

  @override
  void dispose() {
    _targetUserIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentRole() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _currentRole = null);
        return;
      }

      final row = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _currentRole = row?['role']?.toString();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignRole() async {
    final targetUserId = _targetUserIdController.text.trim();
    if (targetUserId.isEmpty) {
      _showSnack('Ingresa el user_id del usuario');
      return;
    }
    if (_currentRole != 'super_admin') {
      _showSnack('No tienes permisos para asignar roles');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('profiles')
          .update({'role': _selectedRole})
          .eq('user_id', targetUserId)
          .select('user_id,role')
          .maybeSingle();

      if (!mounted) return;
      _showSnack('Rol actualizado: $_selectedRole');
      _targetUserIdController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al actualizar rol: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _currentRole == 'super_admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu rol actual: ${_currentRole ?? 'desconocido'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (!canManage)
                      const Text(
                        'Solo `super_admin` puede asignar roles.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetUserIdController,
                      enabled: canManage,
                      decoration: const InputDecoration(
                        labelText: 'user_id del usuario (UUID)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol a asignar',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r,
                              child: Text(r),
                            ),
                          )
                          .toList(),
                      onChanged: canManage
                          ? (value) {
                              if (value == null) return;
                              setState(() => _selectedRole = value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canManage && !_isLoading ? _assignRole : null,
                        child: const Text('Asignar rol'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tip: para sacar el user_id del usuario, puedes verlo en Auth/Users de Supabase o dármelo y te digo dónde consultarlo.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

