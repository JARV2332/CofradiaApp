import 'dart:convert';
import 'package:http/http.dart' as http;

class ReporteService {
  static const String baseUrl = 'http://localhost:5000/api';

  Future<List<Map<String, dynamic>>> getReporteCofrades() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reporte_cofrades'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['value']);
      } else {
        throw Exception('Error al obtener el reporte de cofrades');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
