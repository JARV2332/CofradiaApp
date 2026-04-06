import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String keyApiUrl = 'api_url';
  static const String defaultUrl = 'http://localhost:5000/api';
  
  static String? _customUrl;
  
  // Getter para compatibilidad con el código existente
  static String get baseUrl => _customUrl ?? defaultUrl;
  
  // Obtener la URL configurada
  static Future<String> getApiUrl() async {
    if (_customUrl != null) return _customUrl!;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyApiUrl) ?? defaultUrl;
  }
  
  // Establecer una URL personalizada
  static Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyApiUrl, url);
    _customUrl = url;
  }
  
  // Reiniciar a la URL por defecto
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyApiUrl, defaultUrl);
    _customUrl = defaultUrl;
  }
}
