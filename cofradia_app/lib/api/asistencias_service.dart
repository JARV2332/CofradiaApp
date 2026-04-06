import 'dart:convert';
import 'package:cofradia_app/models/asistencia.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class AsistenciasService {
  final String baseUrl = ApiConfig.baseUrl;

  // Obtener todas las asistencias
  Future<List<Asistencia>> getAsistencias() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/asistencias'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar asistencias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar asistencias: $e');
    }
  }

  // Obtener una asistencia por ID
  Future<Asistencia> getAsistencia(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/asistencias/$id'));
      if (response.statusCode == 200) {
        return Asistencia.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al cargar asistencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar asistencia: $e');
    }
  }

  // Crear una nueva asistencia
  Future<Asistencia> createAsistencia(Asistencia asistencia) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/asistencias'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(asistencia.toJson()),
      );
      if (response.statusCode == 201) {
        return Asistencia.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear asistencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear asistencia: $e');
    }
  }

  // Actualizar una asistencia
  Future<Asistencia> updateAsistencia(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/asistencias/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      if (response.statusCode == 200) {
        return Asistencia.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar asistencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar asistencia: $e');
    }
  }

  // Eliminar una asistencia
  Future<void> deleteAsistencia(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/asistencias/$id'));
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar asistencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar asistencia: $e');
    }
  }
}
