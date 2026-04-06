import 'package:flutter/material.dart';
import '../api/api_config.dart';
import '../api/api_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _currentUrl = '';
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentUrl() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final url = await ApiConfig.getApiUrl();
      setState(() {
        _currentUrl = url;
        _urlController.text = url;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la configuración')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    final newUrl = _urlController.text.trim();
    
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La URL no puede estar vacía')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ApiConfig.setApiUrl(newUrl);
      await _apiService.initializeApiUrl(newUrl);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuración guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _currentUrl = newUrl;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la configuración'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetToDefault() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ApiConfig.resetToDefault();
      await ApiService.initializeApiUrl();
      await _loadCurrentUrl();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuración restablecida a los valores por defecto'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al restablecer la configuración'),
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
        title: Text('Configuración'),
        backgroundColor: Colors.grey[800],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Text(
                    'Configuración del Servidor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Configure la dirección del servidor de la Cofradía. Esta configuración afecta a todas las operaciones de la aplicación.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Campo para la URL del API
                  Text(
                    'URL del Servidor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'http://192.168.56.1:8095',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'URL actual: $_currentUrl',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Guardar'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetToDefault,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Restablecer'),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Consejos para la configuración
                  Card(
                    elevation: 2,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consejos de Configuración:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildTip(
                            'Para dispositivos físicos, use la IP local de su servidor (ej. 192.168.1.100:8095).',
                          ),
                          _buildTip(
                            'Para emuladores de Android, use 10.0.2.2:8095 para acceder a localhost.',
                          ),
                          _buildTip(
                            'Para iOS Simulator, use localhost:8095.',
                          ),
                          _buildTip(
                            'Asegúrese de incluir el protocolo (http:// o https://) y el puerto si es necesario.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue[800]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
