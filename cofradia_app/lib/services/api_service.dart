import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asistencia.dart';
import '../models/cofrade.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl;
  final SupabaseClient _supabase = Supabase.instance.client;
  final bool useFakeData = false;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Datos falsos para desarrollo
  static List<Cofrade> _fakeCofradesList = [
    Cofrade(
      id: '1',
      nombre: 'Juan',
      apellidos: 'Pérez García',
      telefono: '123456789',
      email: 'juan.perez@example.com',
      categoria: 'Sección 1',
      estado: 'División A',
      fechaAlta: '2023-01-15',
      fotoUrl: '',
    ),
    Cofrade(
      id: '2',
      nombre: 'María',
      apellidos: 'González López',
      telefono: '987654321',
      email: 'maria.gonzalez@example.com',
      categoria: 'Sección 2',
      estado: 'División B',
      fechaAlta: '2023-02-20',
      fotoUrl: '',
    ),
    Cofrade(
      id: '3',
      nombre: 'Carlos',
      apellidos: 'Martínez Ruiz',
      telefono: '456789123',
      email: 'carlos.martinez@example.com',
      categoria: 'Sección 3',
      estado: 'División C',
      fechaAlta: '2023-03-10',
      fotoUrl: '',
    ),
    Cofrade(
      id: '4',
      nombre: 'Ana',
      apellidos: 'Fernández Torres',
      telefono: '321654987',
      email: 'ana.fernandez@example.com',
      categoria: 'Sección 4',
      estado: 'División D',
      fechaAlta: '2023-04-05',
      fotoUrl: '',
    ),
    Cofrade(
      id: '5',
      nombre: 'Luis',
      apellidos: 'Rodríguez Sánchez',
      telefono: '654321789',
      email: 'luis.rodriguez@example.com',
      categoria: 'Sección 5',
      estado: 'División E',
      fechaAlta: '2023-05-12',
      fotoUrl: '',
    ),
  ];

  static List<Evento> _fakeEventosList = [
    Evento(
      id: '1',
      nombre: 'Procesión de Semana Santa',
      descripcion: 'Procesión tradicional de Semana Santa por las calles del centro histórico',
      fecha: '2025-04-13',
      hora: '18:00',
      lugar: 'Plaza Central',
      tipo: 'Religioso',
      estado: 'activo',
      cupo: 50,
    ),
    Evento(
      id: '2',
      nombre: 'Reunión General',
      descripcion: 'Reunión general de todos los cofrades para planificar las actividades del año',
      fecha: '2025-03-15',
      hora: '19:30',
      lugar: 'Salón de la Cofradía',
      tipo: 'Administrativo',
      estado: 'activo',
      cupo: 100,
    ),
    Evento(
      id: '3',
      nombre: 'Bendición de Túnicas',
      descripcion: 'Ceremonia de bendición de las nuevas túnicas de los cofrades',
      fecha: '2025-02-28',
      hora: '17:00',
      lugar: 'Iglesia San Miguel',
      tipo: 'Religioso',
      estado: 'completado',
      cupo: 30,
    ),
  ];

  static List<Usuario> _fakeUsuariosList = [
    Usuario(
      id: '1',
      nombre: 'Admin Principal',
      email: 'admin@cofradia.com',
      telefono: '111222333',
      rol: 'Administrador',
      estado: 'activo',
      fechaIngreso: DateTime(2023, 1, 1),
      fechaRegistro: DateTime(2023, 1, 1),
      esDirectiva: true,
    ),
    Usuario(
      id: '2',
      nombre: 'Secretario Cofradia',
      email: 'secretario@cofradia.com',
      telefono: '444555666',
      rol: 'Secretario',
      estado: 'activo',
      fechaIngreso: DateTime(2023, 1, 15),
      fechaRegistro: DateTime(2023, 1, 15),
      esDirectiva: true,
    ),
  ];

  static List<Asistencia> _fakeAsistenciasList = [
    // Las asistencias se crearán dinámicamente cuando se necesiten
    // para evitar referencias circulares con los objetos completos
  ];

  // Eventos
  Future<List<Evento>> getEventos() async {
    if (useFakeData) {
      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_fakeEventosList);
    }

    final response = await _supabase
        .from('eventos')
        .select('id,nombre,descripcion,fecha,hora,lugar,tipo,estado,cupo')
        .order('fecha', ascending: true);

    return (response as List<dynamic>)
        .map((e) => Evento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Evento> getEvento(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final evento = _fakeEventosList.firstWhere((e) => e.id == id);
      return evento;
    }

    final response = await _supabase
        .from('eventos')
        .select('id,nombre,descripcion,fecha,hora,lugar,tipo,estado,cupo')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      throw Exception('Evento no encontrado');
    }

    return Evento.fromJson(response as Map<String, dynamic>);
  }

  Future<Evento> createEvento(Evento evento) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 800));
      final newId = (_fakeEventosList.length + 1).toString();
      final newEvento = Evento(
        id: newId,
        nombre: evento.nombre,
        descripcion: evento.descripcion,
        fecha: evento.fecha,
        hora: evento.hora,
        lugar: evento.lugar,
        tipo: evento.tipo,
        estado: evento.estado,
        cupo: evento.cupo,
      );
      _fakeEventosList.add(newEvento);
      return newEvento;
    }

    final response = await _supabase
        .from('eventos')
        .insert(evento.toJson())
        .select('id,nombre,descripcion,fecha,hora,lugar,tipo,estado,cupo')
        .maybeSingle();

    if (response == null) {
      throw Exception('Error al crear evento');
    }

    return Evento.fromJson(response as Map<String, dynamic>);
  }

  Future<Evento> updateEvento(String id, Evento evento) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 600));
      final index = _fakeEventosList.indexWhere((e) => e.id == id);
      if (index != -1) {
        final updatedEvento = Evento(
          id: id,
          nombre: evento.nombre,
          descripcion: evento.descripcion,
          fecha: evento.fecha,
          hora: evento.hora,
          lugar: evento.lugar,
          tipo: evento.tipo,
          estado: evento.estado,
          cupo: evento.cupo,
        );
        _fakeEventosList[index] = updatedEvento;
        return updatedEvento;
      } else {
        throw Exception('Evento no encontrado');
      }
    }

    final response = await _supabase
        .from('eventos')
        .update(evento.toJson())
        .eq('id', id)
        .select('id,nombre,descripcion,fecha,hora,lugar,tipo,estado,cupo')
        .maybeSingle();

    if (response == null) {
      throw Exception('Error al actualizar evento');
    }

    return Evento.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteEvento(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final index = _fakeEventosList.indexWhere((e) => e.id == id);
      if (index != -1) {
        _fakeEventosList.removeAt(index);
      } else {
        throw Exception('Evento no encontrado');
      }
      return;
    }

    await _supabase.from('eventos').delete().eq('id', id);
  }

  // Cofrades
  Future<List<Cofrade>> getCofrades() async {
    if (useFakeData) {
      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 500));
      print('Cargando datos falsos de cofrades...');
      return List.from(_fakeCofradesList);
    }

    final response = await _supabase
        .from('cofrades')
        .select('*')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Cofrade.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cofrade> getCofrade(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final cofrade = _fakeCofradesList.firstWhere((c) => c.id == id);
      return cofrade;
    }

    final response = await _supabase
        .from('cofrades')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null) throw Exception('Cofrade no encontrado');
    return Cofrade.fromJson(response as Map<String, dynamic>);
  }

  Future<Cofrade> createCofrade(Cofrade cofrade) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Generar un ID único para el nuevo cofrade
      final newId = (_fakeCofradesList.length + 1).toString();
      final newCofrade = Cofrade(
        id: newId,
        nombre: cofrade.nombre,
        apellidos: cofrade.apellidos,
        telefono: cofrade.telefono,
        email: cofrade.email,
        categoria: cofrade.categoria,
        estado: cofrade.estado,
        fechaAlta: cofrade.fechaAlta,
        agrupacion: cofrade.agrupacion,
        fotoUrl: cofrade.fotoUrl,
      );
      
      _fakeCofradesList.add(newCofrade);
      print('Cofrade creado exitosamente con ID: $newId');
      return newCofrade;
    }

    final response = await _supabase
        .from('cofrades')
        .insert(cofrade.toJson())
        .select('*')
        .maybeSingle();

    if (response == null) throw Exception('Error al crear cofrade');
    return Cofrade.fromJson(response as Map<String, dynamic>);
  }

  Future<Cofrade> updateCofrade(String id, Cofrade cofrade) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final index = _fakeCofradesList.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updatedCofrade = Cofrade(
          id: id,
          nombre: cofrade.nombre,
          apellidos: cofrade.apellidos,
          telefono: cofrade.telefono,
          email: cofrade.email,
          categoria: cofrade.categoria,
          estado: cofrade.estado,
          fechaAlta: cofrade.fechaAlta,
          agrupacion: cofrade.agrupacion,
          fotoUrl: cofrade.fotoUrl,
        );
        
        _fakeCofradesList[index] = updatedCofrade;
        print('Cofrade actualizado exitosamente: $id');
        return updatedCofrade;
      } else {
        throw Exception('Cofrade no encontrado');
      }
    }

    final response = await _supabase
        .from('cofrades')
        .update(cofrade.toJson())
        .eq('id', id)
        .select('*')
        .maybeSingle();

    if (response == null) throw Exception('Error al actualizar cofrade');
    return Cofrade.fromJson(response as Map<String, dynamic>);
  }

  /// Sube la imagen al bucket `cofrade-fotos` y devuelve la URL pública.
  Future<String> uploadCofradeFoto({
    required String cofradeId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (useFakeData) {
      return 'https://picsum.photos/seed/$cofradeId/300/400';
    }
    final ext = contentType.toLowerCase().contains('png') ? 'png' : 'jpeg';
    final objectPath = '$cofradeId/foto.$ext';
    await _supabase.storage.from('cofrade-fotos').uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _supabase.storage.from('cofrade-fotos').getPublicUrl(objectPath);
  }

  Future<void> deleteCofrade(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final index = _fakeCofradesList.indexWhere((c) => c.id == id);
      if (index != -1) {
        _fakeCofradesList.removeAt(index);
        print('Cofrade eliminado exitosamente: $id');
      } else {
        throw Exception('Cofrade no encontrado');
      }
      return;
    }

    await _supabase.from('cofrades').delete().eq('id', id);
  }

  Future<List<String>> _getCatalogItems(String tipo) async {
    try {
      final rows = await _supabase
          .from('catalogo_cofradia')
          .select('nombre')
          .eq('tipo', tipo)
          .eq('activo', true)
          .order('orden', ascending: true);

      return (rows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['nombre']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getSeccionesCatalogo() async {
    final items = await _getCatalogItems('seccion');
    final normalized = items.where((name) {
      return RegExp(r'^Sección\s+\d+$', caseSensitive: false).hasMatch(name);
    }).toList();
    if (normalized.length >= 31) return normalized;
    return List<String>.generate(31, (index) => 'Sección ${index + 1}');
  }

  Future<List<String>> getDivisionesCatalogo() async {
    final items = await _getCatalogItems('division');
    final normalized = items.where((name) {
      return RegExp(r'^División\s+\d+$', caseSensitive: false).hasMatch(name);
    }).toList();
    if (normalized.length >= 20) return normalized;
    return List<String>.generate(20, (index) => 'División ${index + 1}');
  }

  Future<List<String>> getAgrupacionesCatalogo() async {
    final items = await _getCatalogItems('agrupacion');
    if (items.contains('Rosario Viviente') && items.contains('Rosario Perpetuo')) {
      return items;
    }
    return const ['Rosario Viviente', 'Rosario Perpetuo'];
  }

  // Asistencias
  Future<List<Asistencia>> getAsistencias() async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_fakeAsistenciasList);
    }

    final rows = await _supabase
        .from('asistencias')
        .select('id,evento_id,carnet_id,estado,created_at')
        .order('created_at', ascending: false);

    final List<dynamic> list = rows as List<dynamic>;
    final results = <Asistencia>[];

    for (final r in list) {
      final row = r as Map<String, dynamic>;
      final eventoId = row['evento_id'].toString();
      final carnetId = row['carnet_id'].toString();
      final estado = row['estado'].toString();

      final eventoRow = await _supabase
          .from('eventos')
          .select('id,nombre,descripcion,fecha,hora,lugar,tipo,estado,cupo')
          .eq('id', eventoId)
          .maybeSingle();
      final evento = eventoRow == null
          ? null
          : Evento.fromJson(eventoRow as Map<String, dynamic>);

      final carnetRow = await _supabase
          .from('carnets')
          .select('cofrade_id')
          .eq('id', carnetId)
          .maybeSingle();
      final cofradeId =
          carnetRow == null ? null : carnetRow['cofrade_id']?.toString();

      final cofradeRow = cofradeId == null
          ? null
          : await _supabase
              .from('cofrades')
              .select('id,nombre,apellidos,telefono,email,categoria,estado,fecha_alta')
              .eq('id', cofradeId)
              .maybeSingle();
      final cofrade = cofradeRow == null
          ? null
          : Cofrade.fromJson(cofradeRow as Map<String, dynamic>);

      if (evento == null || cofrade == null) continue;

      results.add(
        Asistencia(
          id: row['id'].toString(),
          evento: evento,
          cofrade: cofrade,
          estado: estado,
        ),
      );
    }

    return results;
  }

  Future<Asistencia> getAsistencia(String id) async {
    final list = await getAsistencias();
    final found = list.where((a) => a.id == id);
    if (found.isEmpty) throw Exception('Asistencia no encontrada');
    return found.first;
  }

  Future<Asistencia> createAsistencia(Asistencia asistencia) async {
    // Elegimos el carnet activo más reciente del cofrade.
    final carnetRow = await _supabase
        .from('carnets')
        .select('id,cofrade_id')
        .eq('cofrade_id', asistencia.cofrade.id)
        .eq('active', true)
        .order('issued_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (carnetRow == null) {
      throw Exception('El cofrade no tiene un carnet activo');
    }

    final insert = await _supabase
        .from('asistencias')
        .insert({
          'evento_id': asistencia.evento.id,
          'carnet_id': carnetRow['id'].toString(),
          'estado': asistencia.estado,
        })
        .select('id,evento_id,carnet_id,estado,created_at')
        .maybeSingle();

    if (insert == null) {
      throw Exception('Error al crear asistencia');
    }

    // Re-armamos el objeto para que coincida con el modelo actual.
    final evento = await getEvento(insert['evento_id'].toString());
    final cofradeId = (await _supabase
            .from('carnets')
            .select('cofrade_id')
            .eq('id', insert['carnet_id'].toString())
            .maybeSingle())?['cofrade_id']
        ?.toString();

    if (cofradeId == null) throw Exception('Carnet inválido');
    final cofrade = await getCofrade(cofradeId);

    return Asistencia(
      id: insert['id'].toString(),
      evento: evento,
      cofrade: cofrade,
      estado: insert['estado'].toString(),
    );
  }

  Future<Asistencia> updateAsistencia(String id, Asistencia asistencia) async {
    await _supabase
        .from('asistencias')
        .update({'estado': asistencia.estado})
        .eq('id', id);
    return getAsistencia(id);
  }

  Future<void> deleteAsistencia(String id) async {
    await _supabase.from('asistencias').delete().eq('id', id);
  }

  // Usuarios
  Future<List<Usuario>> getUsuarios() async {
    final response = await _supabase
        .from('profiles')
        .select('user_id,role,created_at')
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;
    return rows.map((row) {
      final r = row as Map<String, dynamic>;
      final userId = (r['user_id'] ?? '').toString();
      final role = (r['role'] ?? 'encargado').toString();
      final createdAtRaw = r['created_at']?.toString();
      final createdAt = createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now();

      return Usuario(
        id: userId,
        nombre: 'Usuario ${userId.length >= 8 ? userId.substring(0, 8) : userId}',
        email: userId, // En esta vista usamos el user_id para gestionar roles.
        rol: role,
        estado: 'ACTIVO',
        fechaIngreso: createdAt,
        fechaRegistro: createdAt,
      );
    }).toList();
  }

  Future<Usuario> getUsuario(String id) async {
    final row = await _supabase
        .from('profiles')
        .select('user_id,role,created_at')
        .eq('user_id', id)
        .maybeSingle();

    if (row == null) throw Exception('Usuario no encontrado');

    final createdAtRaw = row['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    final userId = row['user_id'].toString();
    final shortId = userId.length >= 8 ? userId.substring(0, 8) : userId;

    return Usuario(
      id: userId,
      nombre: 'Usuario $shortId',
      email: userId,
      rol: (row['role'] ?? 'encargado').toString(),
      estado: 'ACTIVO',
      fechaIngreso: createdAt,
      fechaRegistro: createdAt,
    );
  }

  Future<Usuario> createUsuario(Usuario usuario) async {
    final userId = usuario.email.trim();
    if (userId.isEmpty) {
      throw Exception('Debes indicar un user_id válido');
    }

    final row = await _supabase
        .from('profiles')
        .upsert({
          'user_id': userId,
          'role': usuario.rol.toLowerCase(),
        })
        .select('user_id,role,created_at')
        .maybeSingle();

    if (row == null) throw Exception('No se pudo crear/actualizar usuario');

    final createdAtRaw = row['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    final savedUserId = row['user_id'].toString();
    final savedShortId = savedUserId.length >= 8
        ? savedUserId.substring(0, 8)
        : savedUserId;

    return Usuario(
      id: savedUserId,
      nombre: 'Usuario $savedShortId',
      email: savedUserId,
      rol: (row['role'] ?? 'encargado').toString(),
      estado: 'ACTIVO',
      fechaIngreso: createdAt,
      fechaRegistro: createdAt,
    );
  }

  Future<Usuario> updateUsuario(String id, Usuario usuario) async {
    final row = await _supabase
        .from('profiles')
        .update({
          'role': usuario.rol.toLowerCase(),
        })
        .eq('user_id', id)
        .select('user_id,role,created_at')
        .maybeSingle();

    if (row == null) throw Exception('No se pudo actualizar el rol');

    final createdAtRaw = row['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    final updatedUserId = row['user_id'].toString();
    final updatedShortId = updatedUserId.length >= 8
        ? updatedUserId.substring(0, 8)
        : updatedUserId;

    return Usuario(
      id: updatedUserId,
      nombre: 'Usuario $updatedShortId',
      email: updatedUserId,
      rol: (row['role'] ?? 'encargado').toString(),
      estado: 'ACTIVO',
      fechaIngreso: createdAt,
      fechaRegistro: createdAt,
    );
  }

  Future<void> deleteUsuario(String id) async {
    // En vez de borrar el perfil, lo regresamos al rol mínimo.
    await _supabase
        .from('profiles')
        .update({'role': 'encargado'})
        .eq('user_id', id);
  }
}
