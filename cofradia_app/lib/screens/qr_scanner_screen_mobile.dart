import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:postgrest/postgrest.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evento.dart';
import '../services/api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isLoading = true;
  bool _isHandlingQr = false;
  bool _cameraPermissionGranted = false;
  List<Evento> _eventosActivos = [];
  String? _selectedEventoId;
  String? _carnetId;
  Map<String, dynamic>? _cofradeData;

  @override
  void initState() {
    super.initState();
    _loadEventosActivos();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _loadEventosActivos() async {
    try {
      setState(() => _isLoading = true);
      final hasPermission = await _ensureCameraPermission();
      final eventos = await _apiService.getEventos();
      final activos = eventos.where((e) => e.estado.toLowerCase() == 'activo').toList();
      setState(() {
        _cameraPermissionGranted = hasPermission;
        _eventosActivos = activos;
        _selectedEventoId = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error cargando eventos: $e');
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingQr || _selectedEventoId == null || !_cameraPermissionGranted) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _handleQr(raw);
  }

  Future<void> _handleQr(String raw) async {
    final carnetId = _parseCarnetId(raw);
    if (carnetId == null) {
      _showSnack('QR inválido');
      return;
    }

    setState(() {
      _isHandlingQr = true;
      _carnetId = carnetId;
    });

    await _cameraController.stop();
    await _loadCofradeForCarnet(carnetId);
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final requested = await Permission.camera.request();
    return requested.isGranted;
  }

  String? _parseCarnetId(String qrCode) {
    final trimmed = qrCode.trim();
    if (trimmed.isEmpty) return null;
    if (_looksLikeUuid(trimmed)) return trimmed;
    try {
      final data = jsonDecode(trimmed);
      if (data is Map) {
        final id = data['carnet_id'] ?? data['id'] ?? data['carnetId'];
        final parsed = id?.toString();
        if (parsed != null && _looksLikeUuid(parsed)) return parsed;
      }
    } catch (_) {}
    return null;
  }

  bool _looksLikeUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  Future<void> _loadCofradeForCarnet(String carnetId) async {
    try {
      final carnetRow = await _supabase
          .from('carnets')
          .select('cofrade_id')
          .eq('id', carnetId)
          .maybeSingle();

      if (carnetRow == null) {
        _showSnack('Carnet no válido o inexistente');
        await _restartScanner();
        return;
      }

      final cofradeId = carnetRow['cofrade_id']?.toString();
      if (cofradeId == null) {
        _showSnack('Carnet inválido');
        await _restartScanner();
        return;
      }

      final cofradeRow = await _supabase
          .from('cofrades')
          .select('id,nombre,apellidos,email,telefono,categoria,estado,agrupacion,fecha_alta')
          .eq('id', cofradeId)
          .maybeSingle();

      if (cofradeRow == null) {
        _showSnack('Cofrade no encontrado');
        await _restartScanner();
        return;
      }

      setState(() => _cofradeData = cofradeRow as Map<String, dynamic>);
      await _showCofradeDialog();
    } catch (e) {
      _showSnack('Error cargando carnet');
      await _restartScanner();
    }
  }

  Future<void> _showCofradeDialog() async {
    if (_cofradeData == null) return;
    final nombre = _cofradeData?['nombre']?.toString() ?? '';
    final apellidos = _cofradeData?['apellidos']?.toString() ?? '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cofrade identificado'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$nombre $apellidos',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              _infoRow('Sección', _cofradeData?['categoria']?.toString() ?? ''),
              _infoRow('División', _cofradeData?['estado']?.toString() ?? ''),
              _infoRow('Agrupación', _cofradeData?['agrupacion']?.toString() ?? ''),
              _infoRow('Email', _cofradeData?['email']?.toString() ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _restartScanner();
            },
            child: const Text('Escanear otro'),
          ),
          ElevatedButton(
            onPressed: _registrarAsistencia,
            child: const Text('Registrar Asistencia'),
          ),
        ],
      ),
    );
  }

  Future<void> _registrarAsistencia() async {
    final eventoId = _selectedEventoId;
    final carnetId = _carnetId;
    final nombre = _cofradeData?['nombre']?.toString() ?? '';
    final apellidos = _cofradeData?['apellidos']?.toString() ?? '';

    if (eventoId == null) {
      _showSnack('Selecciona un evento activo');
      return;
    }
    if (carnetId == null) {
      _showSnack('Carnet no disponible');
      return;
    }

    try {
      await _supabase
          .from('asistencias')
          .insert({'evento_id': eventoId, 'carnet_id': carnetId})
          .select('id')
          .maybeSingle();

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Asistencia registrada: ${(nombre + ' ' + apellidos).trim()}');
      await _restartScanner();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e.code == '23505') {
        _showSnack('Este carnet ya fue registrado para este evento');
      } else {
        _showSnack('Error al registrar asistencia: ${e.message}');
      }
      await _restartScanner();
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Error al registrar asistencia');
      await _restartScanner();
    }
  }

  Future<void> _restartScanner() async {
    if (!mounted) return;
    final hasPermission = await _ensureCameraPermission();
    setState(() {
      _isHandlingQr = false;
      _carnetId = null;
      _cofradeData = null;
      _cameraPermissionGranted = hasPermission;
    });
    if (hasPermission && _selectedEventoId != null) {
      await _cameraController.start();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner QR - Asistencias v2')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    value: _selectedEventoId,
                    decoration: const InputDecoration(
                      labelText: 'Selecciona actividad/evento',
                      border: OutlineInputBorder(),
                    ),
                    items: _eventosActivos
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.id,
                            child: Text(e.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedEventoId = value);
                      if (value == null) {
                        _cameraController.stop();
                      } else if (_cameraPermissionGranted) {
                        _cameraController.start();
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final granted = await _ensureCameraPermission();
                          if (!mounted) return;
                          setState(() => _cameraPermissionGranted = granted);
                          if (!granted) {
                            _showSnack('Debes conceder permiso de cámara');
                          } else if (_selectedEventoId != null) {
                            await _cameraController.start();
                          }
                        },
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Permiso cámara'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _cameraPermissionGranted
                            ? () => _cameraController.toggleTorch()
                            : null,
                        icon: const Icon(Icons.flash_on),
                        tooltip: 'Linterna',
                      ),
                      IconButton(
                        onPressed: _cameraPermissionGranted
                            ? () => _cameraController.switchCamera()
                            : null,
                        icon: const Icon(Icons.cameraswitch),
                        tooltip: 'Cambiar cámara',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: !_cameraPermissionGranted
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Sin permiso de cámara. Pulsa "Permiso cámara" para habilitar el escáner.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _selectedEventoId == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Primero selecciona un evento para habilitar la cámara.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            MobileScanner(
                              controller: _cameraController,
                              onDetect: _onDetect,
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                color: Colors.black54,
                                child: const Text(
                                  'QR MOVIL V2',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
