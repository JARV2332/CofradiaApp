import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CofradeQRScreen extends StatelessWidget {
  final Map<String, dynamic> cofrade;

  const CofradeQRScreen({
    Key? key,
    required this.cofrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final qrData = _generateQRData(cofrade);

    return Scaffold(
      appBar: AppBar(
        title: Text('Carnet de Cofrade'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implementar compartir carnet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compartir carnet (función por implementar)')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Carnet digital
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: size.width * 0.9,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Encabezado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'COFRADÍA',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Image.asset(
                              'assets/logo.png',
                              height: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.church,
                                  size: 40,
                                  color: Colors.deepPurple,
                                );
                              },
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Foto/Avatar del cofrade
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text(
                            _getInitials(cofrade['nombre'] ?? 'N/A'),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Información del cofrade
                        Text(
                          cofrade['nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 8),
                        
                        Text(
                          cofrade['email'] ?? 'Sin email',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        if (cofrade['cargo'] != null) ...[
                          SizedBox(height: 8),
                          Text(
                            cofrade['cargo'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 24),
                        
                        // Código QR
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // ID del cofrade
                        Text(
                          'ID: ${cofrade['id'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Fecha de ingreso
                        Text(
                          'Miembro desde: ${cofrade['fechaIngreso'] ?? cofrade['fecha_ingreso'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Instrucciones
                Text(
                  'Este código QR es personal y debe ser presentado en los eventos de la Cofradía para registrar su asistencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Botón para volver
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('Volver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Genera los datos para el código QR
  String _generateQRData(Map<String, dynamic> cofrade) {
    // Formato: {"id": 1, "nombre": "Juan Pérez", "email": "juan@example.com"}
    return '{"id": ${cofrade['id']}, "nombre": "${cofrade['nombre']}", "email": "${cofrade['email']}"}';
  }
  
  // Obtener iniciales del nombre
  String _getInitials(String name) {
    if (name.isEmpty) return 'N/A';
    
    List<String> parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return (parts[0][0] + (parts.length > 1 ? parts[1][0] : '')).toUpperCase();
  }
}
