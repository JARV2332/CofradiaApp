import 'package:flutter/material.dart';
import 'dart:convert';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? _scannedCode;
  Map<String, dynamic>? _cofradeData;

  void _handleQRCode(String qrCode) {
    if (!mounted) return;

    setState(() {
      _scannedCode = qrCode;
    });

    try {
      // Intentar parsear el QR como JSON
      final data = jsonDecode(qrCode);
      if (data['tipo'] == 'COFRADE_CARNET' && data['cofrade'] != null) {
        setState(() {
          _cofradeData = data['cofrade'];
        });

        // Mostrar diálogo con la información
        _showCofradeDialog();
      }
    } catch (e) {
      // Si no es JSON válido, mostrar el código tal cual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código QR escaneado: $qrCode'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showCofradeDialog() {
    if (_cofradeData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cofrade Identificado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_cofradeData!['nombre']} ${_cofradeData!['apellidos']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildInfoRow('ID', _cofradeData!['id'].toString()),
              _buildInfoRow('Email', _cofradeData!['email']),
              _buildInfoRow('Teléfono', _cofradeData!['telefono']),
              _buildInfoRow('Sección', _cofradeData!['seccion']),
              _buildInfoRow('División', _cofradeData!['division']),
              _buildInfoRow('Fecha Alta', _cofradeData!['fecha_alta']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scannedCode = null;
                _cofradeData = null;
              });
            },
            child: const Text('Escanear Otro'),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí puedes agregar la lógica para registrar la asistencia
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Asistencia registrada para ${_cofradeData!['nombre']} ${_cofradeData!['apellidos']}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context); // Volver a la pantalla anterior
            },
            child: const Text('Registrar Asistencia'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR - Tomar Asistencia'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 120,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 30),
              const Text(
                'Escáner de QR para Asistencia',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Haz clic en el botón para simular el escaneo de un carnet',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Simular escaneo para pruebas
                  _handleQRCode('''
{
  "tipo": "COFRADE_CARNET",
  "cofrade": {
    "id": "1",
    "nombre": "Juan",
    "apellidos": "Pérez García",
    "email": "juan.perez@example.com",
    "telefono": "123456789",
    "seccion": "Sección 1",
    "division": "División A",
    "fecha_alta": "2023-01-15"
  }
}
                  ''');
                },
                icon: const Icon(Icons.qr_code, size: 30),
                label: const Text(
                  'SIMULAR ESCANEO (DEMO)',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_scannedCode != null && _cofradeData != null) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        '${_cofradeData!['nombre']} ${_cofradeData!['apellidos']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${_cofradeData!['id']}'),
                      Text('Sección: ${_cofradeData!['seccion']}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
