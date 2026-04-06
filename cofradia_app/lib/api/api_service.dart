import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asistencia.dart';
import '../models/cofrade.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import 'api_config.dart';

class ApiService {
  final String baseUrl;
  final bool useFakeData = true; // Cambiar a false cuando la BD esté disponible

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> initializeApiUrl(String url) async {
    // Actualizar la URL base de la API
    ApiConfig.baseUrl = url;
  }

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
    
    final response = await http.get(Uri.parse('$baseUrl/eventos'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData is Map && jsonData.containsKey('value')) {
        final List<dynamic> eventos = jsonData['value'];
        return eventos.map((json) => Evento.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta no esperado');
    } else {
      throw Exception('Error al obtener eventos: ${response.statusCode}');
    }
  }

  Future<Evento> getEvento(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final evento = _fakeEventosList.firstWhere((e) => e.id == id);
      return evento;
    }
    
    final response = await http.get(Uri.parse('$baseUrl/eventos/$id'));
    if (response.statusCode == 200) {
      return Evento.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener evento');
    }
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
    
    final response = await http.post(
      Uri.parse('$baseUrl/eventos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(evento.toJson()),
    );
    if (response.statusCode == 201) {
      return Evento.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear evento');
    }
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
    
    final response = await http.put(
      Uri.parse('$baseUrl/eventos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(evento.toJson()),
    );
    if (response.statusCode == 200) {
      return Evento.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar evento');
    }
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
    
    final response = await http.delete(Uri.parse('$baseUrl/eventos/$id'));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar evento');
    }
  }

  // Cofrades
  Future<List<Cofrade>> getCofrades() async {
    if (useFakeData) {
      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_fakeCofradesList);
    }
    
    final response = await http.get(Uri.parse('$baseUrl/cofrades'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      
      if (jsonData is Map && jsonData.containsKey('value')) {
        final List<dynamic> cofrades = jsonData['value'];
        return cofrades.map((json) => Cofrade.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta no esperado');
    } else {
      throw Exception('Error al obtener cofrades: ${response.statusCode}');
    }
  }

  Future<Cofrade> getCofrade(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final cofrade = _fakeCofradesList.firstWhere((c) => c.id == id);
      return cofrade;
    }
    
    final response = await http.get(Uri.parse('$baseUrl/cofrades/$id'));
    if (response.statusCode == 200) {
      return Cofrade.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener cofrade');
    }
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
      );
      
      _fakeCofradesList.add(newCofrade);
      return newCofrade;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/cofrades'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(cofrade.toJson()),
    );
    
    if (response.statusCode == 201) {
      return Cofrade.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear cofrade. Status: ${response.statusCode}, Respuesta: ${response.body}');
    }
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
        );
        
        _fakeCofradesList[index] = updatedCofrade;
        return updatedCofrade;
      } else {
        throw Exception('Cofrade no encontrado');
      }
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl/cofrades/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(cofrade.toJson()),
    );
    
    if (response.statusCode == 200) {
      return Cofrade.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar cofrade. Status: ${response.statusCode}, Respuesta: ${response.body}');
    }
  }

  Future<void> deleteCofrade(String id) async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final index = _fakeCofradesList.indexWhere((c) => c.id == id);
      if (index != -1) {
        _fakeCofradesList.removeAt(index);
      } else {
        throw Exception('Cofrade no encontrado');
      }
      return;
    }
    
    final response = await http.delete(Uri.parse('$baseUrl/cofrades/$id'));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar cofrade');
    }
  }

  // Asistencias
  Future<List<Asistencia>> getAsistencias() async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_fakeAsistenciasList);
    }
    
    final response = await http.get(Uri.parse('$baseUrl/asistencias'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData is Map && jsonData.containsKey('value')) {
        final List<dynamic> asistencias = jsonData['value'];
        return asistencias.map((json) => Asistencia.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta no esperado');
    } else {
      throw Exception('Error al obtener asistencias: ${response.statusCode}');
    }
  }

  Future<Asistencia> getAsistencia(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/asistencias/$id'));
    if (response.statusCode == 200) {
      return Asistencia.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener asistencia');
    }
  }

  Future<Asistencia> createAsistencia(Asistencia asistencia) async {
    final response = await http.post(
      Uri.parse('$baseUrl/asistencias'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(asistencia.toJson()),
    );
    if (response.statusCode == 201) {
      return Asistencia.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear asistencia');
    }
  }

  Future<Asistencia> updateAsistencia(String id, Asistencia asistencia) async {
    final response = await http.put(
      Uri.parse('$baseUrl/asistencias/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(asistencia.toJson()),
    );
    if (response.statusCode == 200) {
      return Asistencia.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar asistencia');
    }
  }

  Future<void> deleteAsistencia(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/asistencias/$id'));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar asistencia');
    }
  }

  // Usuarios
  Future<List<Usuario>> getUsuarios() async {
    if (useFakeData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_fakeUsuariosList);
    }
    
    final response = await http.get(Uri.parse('$baseUrl/usuarios'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData is Map && jsonData.containsKey('value')) {
        final List<dynamic> usuarios = jsonData['value'];
        return usuarios.map((json) => Usuario.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta no esperado');
    } else {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
  }

  Future<Usuario> getUsuario(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios/$id'));
    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener usuario');
    }
  }

  Future<Usuario> createUsuario(Usuario usuario) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(usuario.toJson()),
    );
    if (response.statusCode == 201) {
      return Usuario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear usuario');
    }
  }

  Future<Usuario> updateUsuario(String id, Usuario usuario) async {
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(usuario.toJson()),
    );
    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar usuario');
    }
  }

  Future<void> deleteUsuario(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/usuarios/$id'));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar usuario');
    }
  }
}
