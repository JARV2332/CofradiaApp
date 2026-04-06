import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show DivElement, ScriptElement, document, window;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart' show PostgrestException;
import '../models/evento.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? _scannedCode;
  String? _carnetId;
  Map<String, dynamic>? _cofradeData;
  bool _isScanning = true;
  final String _viewId = 'qr-scanner-${DateTime.now().millisecondsSinceEpoch}';
  bool _cameraInitialized = false;

  List<Evento> _eventosActivos = [];
  String? _selectedEventoId;

  @override
  void initState() {
    super.initState();
    _loadEventosActivos();
    if (kIsWeb) {
      _initializeWebScanner();
    }
  }

  Future<void> _loadEventosActivos() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('eventos')
          .select('id,nombre,descripcion,fecha,hora,lugar,tipo,estado,cupo')
          .order('fecha', ascending: true);

      final list = response as List<dynamic>;
      final eventos = list
          .map((e) => Evento.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _eventosActivos = eventos;
        // Flujo pedido: primero elegir evento, luego escanear.
        _selectedEventoId = eventos.isNotEmpty ? eventos.first.id : null;
        // Si ya hay un evento preseleccionado, habilitamos el escaneo.
        _isScanning = _selectedEventoId != null;
      });
    } catch (e) {
      // No bloqueamos el scanner si falla la carga del evento.
      if (mounted) {
        setState(() {
          _eventosActivos = [];
          _selectedEventoId = null;
          _isScanning = false;
        });
        _showSnack('Error cargando eventos: $e');
      }
    }
  }

  void _initializeWebScanner() {
    // Crear el elemento HTML para el escáner
    final reader = html.DivElement()
      ..id = _viewId
      ..style.width = '100%'
      ..style.height = '100%';

    // Registrar la vista usando ui_web
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => reader,
    );

    // Cargar la librería y configurar el escáner
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadScannerLibrary();
    });
  }

  void _loadScannerLibrary() {
    // Verificar si la librería ya está cargada
    if (js.context.hasProperty('Html5QrcodeScanner')) {
      _setupScanner();
      return;
    }

    // Cargar la librería
    final script = html.ScriptElement()
      ..src = 'https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js'
      ..type = 'text/javascript';

    script.onLoad.listen((_) {
      _setupScanner();
    });

    script.onError.listen((_) {
      print('Error al cargar la librería del escáner');
    });

    html.document.head?.append(script);
  }

  void _setupScanner() {
    // Registrar callback en JavaScript
    js.context['onQRScanned'] = (String qrData) {
      _handleQRCode(qrData);
    };

    // Crear el escáner con JavaScript usando callMethod
    try {
      js.context.callMethod('eval', ['''
        (function() {
          try {
            const config = { 
              fps: 10,
              qrbox: { width: 250, height: 250 },
              aspectRatio: 1.0
            };

            function onScanSuccess(decodedText, decodedResult) {
              if (window.onQRScanned) {
                window.onQRScanned(decodedText);
              }
            }

            function onScanFailure(error) {
              // Silenciar errores de escaneo fallidos
            }

            const html5QrcodeScanner = new Html5QrcodeScanner(
              "$_viewId",
              config,
              false
            );

            html5QrcodeScanner.render(onScanSuccess, onScanFailure);
            console.log('Escáner QR inicializado');
          } catch (error) {
            console.error('Error al inicializar el escáner:', error);
          }
        })();
      ''']);

      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      print('Error al ejecutar el script del escáner: $e');
    }
  }

  void _handleQRCode(String qrCode) {
    if (!mounted || !_isScanning) return;

    setState(() {
      _scannedCode = qrCode;
      _isScanning = false;
    });

    try {
      final carnetId = _parseCarnetId(qrCode);
      if (carnetId == null) {
        _showSnack('QR inválido: no se pudo obtener carnet_id');
        _restartAfterDelay();
        return;
      }

      if (_selectedEventoId == null) {
        _showSnack('Selecciona un evento antes de escanear');
        _restartAfterDelay();
        return;
      }

      setState(() {
        _carnetId = carnetId;
      });

      // Cargar la info del cofrade desde Supabase
      _loadCofradeForCarnet(carnetId);
    } catch (e) {
      _showSnack('QR detectado pero inválido');
      _restartAfterDelay();
    }
  }

  String? _parseCarnetId(String qrCode) {
    final trimmed = qrCode.trim();
    if (trimmed.isEmpty) return null;

    if (_looksLikeUuid(trimmed)) return trimmed;

    // Compatibilidad: si alguna vez el QR fuera JSON, intentamos leer carnet_id.
    try {
      final data = jsonDecode(trimmed);
      if (data is Map) {
        final id = data['carnet_id'] ?? data['id'] ?? data['carnetId'];
        final idStr = id?.toString();
        if (idStr != null && _looksLikeUuid(idStr)) return idStr;
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

  void _restartAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _scannedCode = null;
          _carnetId = null;
          _cofradeData = null;
        });
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    // Evita que SnackBars anteriores pisen el mensaje.
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loadCofradeForCarnet(String carnetId) async {
    try {
      final supabase = Supabase.instance.client;

      final carnetRow = await supabase
          .from('carnets')
          .select('cofrade_id')
          .eq('id', carnetId)
          .maybeSingle();

      if (carnetRow == null) {
        _showSnack('Carnet no válido o inexistente');
        _restartAfterDelay();
        return;
      }

      final cofradeId = carnetRow['cofrade_id']?.toString();
      if (cofradeId == null) {
        _showSnack('Carnet inválido');
        _restartAfterDelay();
        return;
      }

      final cofradeRow = await supabase
          .from('cofrades')
          .select('id,nombre,apellidos,email,telefono,categoria,estado,fecha_alta')
          .eq('id', cofradeId)
          .maybeSingle();

      if (cofradeRow == null) {
        _showSnack('Cofrade no encontrado');
        _restartAfterDelay();
        return;
      }

      setState(() {
        _cofradeData = cofradeRow as Map<String, dynamic>;
      });

      _showCofradeDialog();
    } catch (e) {
      _showSnack('Error cargando carnet');
      _restartAfterDelay();
    }
  }

  void _showCofradeDialog() {
    if (_cofradeData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Cofrade Identificado'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_cofradeData!['nombre']} ${_cofradeData!['apellidos']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              _buildInfoRow('ID', _cofradeData!['id'].toString()),
              _buildInfoRow('Email', _cofradeData!['email']),
              _buildInfoRow('Teléfono', _cofradeData!['telefono']),
              _buildInfoRow('Sección', _cofradeData!['categoria']),
              _buildInfoRow('División', _cofradeData!['estado']),
              _buildInfoRow('Fecha Alta', _cofradeData!['fecha_alta']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = true;
                _scannedCode = null;
                _cofradeData = null;
                _carnetId = null;
              });
            },
            child: const Text('Escanear Otro'),
          ),
          ElevatedButton(
            onPressed: () async {
              final carnetId = _carnetId;
              final eventoId = _selectedEventoId;
              final nombre = _cofradeData?['nombre']?.toString() ?? '';
              final apellidos = _cofradeData?['apellidos']?.toString() ?? '';

              if (eventoId == null) {
                _showSnack('Selecciona un evento activo antes de registrar');
                return;
              }
              if (carnetId == null) {
                _showSnack('Carnet no disponible');
                return;
              }

              try {
                final supabase = Supabase.instance.client;

                await supabase
                    .from('asistencias')
                    .insert({
                      'evento_id': eventoId,
                      'carnet_id': carnetId,
                    })
                    .select('id')
                    .maybeSingle();

                if (!mounted) return;

                Navigator.pop(context);
                setState(() {
                  _isScanning = true;
                  _scannedCode = null;
                  _cofradeData = null;
                  _carnetId = null;
                });

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Asistencia registrada: ${(nombre + ' ' + apellidos).trim()}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } on PostgrestException catch (e) {
                if (!mounted) return;
                final isDuplicate = e.code == '23505';
                Navigator.pop(context);
                setState(() {
                  _isScanning = true;
                  _scannedCode = null;
                  _cofradeData = null;
                  _carnetId = null;
                });

                _showSnack(
                  isDuplicate
                      ? 'Este carnet ya fue registrado para este evento'
                      : 'Error al registrar asistencia: ${e.message}',
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _isScanning = true;
                  _scannedCode = null;
                  _cofradeData = null;
                  _carnetId = null;
                });
                _showSnack('Error al registrar asistencia');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Registrar Asistencia'),
          ),
        ],
      ),
    );
  }

  static const double _webWideBreakpoint = 900;
  static const double _webMaxContentWidth = 1040;
  /// Tamaño máximo del vídeo QR en escritorio (evita cámara desproporcionada).
  static const double _webScannerMaxSideDesktop = 360;
  /// Ancho máximo del bloque único en móvil/tablet web.
  static const double _webNarrowContentMaxW = 400;
  /// Alto máximo del área de cámara en layout estrecho.
  static const double _webScannerMaxHeightNarrow = 300;

  Widget _webInstructionsContent({required double iconSize}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.qr_code_scanner,
          size: iconSize,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 10),
        const Text(
          'Apunta la cámara hacia el código QR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (_eventosActivos.isNotEmpty)
          DropdownButton<String>(
            value: _selectedEventoId,
            isExpanded: true,
            items: _eventosActivos
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.id,
                    child: Text(
                      '${e.nombre} (${e.fecha} ${e.hora})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedEventoId = value;
                _isScanning = _selectedEventoId != null;
                _scannedCode = null;
                _carnetId = null;
                _cofradeData = null;
              });
            },
          )
        else
          const Text(
            'No hay eventos activos. Crea un evento primero.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 10),
        Text(
          _selectedEventoId == null
              ? 'Selecciona un evento para habilitar el escaneo'
              : (_isScanning ? 'Escaneando...' : 'Listo'),
          style: TextStyle(
            fontSize: 14,
            color: _isScanning ? Colors.orange : Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Panel morado suelto (solo layout ancho en dos columnas).
  Widget _buildWebInstructionsCard({required double iconSize}) {
    return Material(
      color: Colors.deepPurple.shade50,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _webInstructionsContent(iconSize: iconSize),
      ),
    );
  }

  Widget _buildWebScannerView({required double width, required double height}) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      shadowColor: Colors.black26,
      child: SizedBox(
        width: width,
        height: height,
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
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
      body: kIsWeb
          ? LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 1000.0;
                final h = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 800.0;
                final wide = w >= _webWideBreakpoint;

                if (wide) {
                  final rowHeight = (h - 32).clamp(420.0, 640.0);
                  return ColoredBox(
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _webMaxContentWidth,
                          ),
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white,
                            child: SizedBox(
                              height: rowHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 380,
                                        ),
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(20),
                                          child: _buildWebInstructionsCard(
                                            iconSize: 44,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, inner) {
                                        final maxByBox = math.min(
                                          inner.maxWidth - 24,
                                          inner.maxHeight - 24,
                                        );
                                        final s = math
                                            .min(
                                              maxByBox,
                                              _webScannerMaxSideDesktop,
                                            )
                                            .clamp(240.0, _webScannerMaxSideDesktop);
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: _buildWebScannerView(
                                              width: s,
                                              height: s,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Móvil / ventana estrecha: una sola tarjeta; cámara limitada
                final contentW = math.min(w - 32, _webNarrowContentMaxW);
                final camW = contentW - 24;
                final camH = math.min(
                  camW * 0.82,
                  _webScannerMaxHeightNarrow,
                ).clamp(200.0, _webScannerMaxHeightNarrow);

                return ColoredBox(
                  color: Colors.grey.shade100,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentW),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                color: Colors.deepPurple.shade50,
                                padding: const EdgeInsets.all(18),
                                child: _webInstructionsContent(
                                  iconSize: (w * 0.08).clamp(36.0, 44.0),
                                ),
                              ),
                              Divider(height: 1, color: Colors.grey.shade300),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Center(
                                  child: _buildWebScannerView(
                                    width: camW,
                                    height: camH,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'El escáner de QR con cámara está disponible en:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• Navegador Web (Chrome, Edge, Firefox)\n• Aplicación Android',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Demo: un carnetId dummy (en producción escanea un QR real).
                        _handleQRCode('00000000-0000-0000-0000-000000000000');
                      },
                      icon: const Icon(Icons.qr_code, size: 28),
                      label: const Text(
                        'Modo Demo',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Limpiar recursos
    if (kIsWeb) {
      try {
        js.context.deleteProperty('onQRScanned');
      } catch (e) {
        print('Error al limpiar callback: $e');
      }
    }
    super.dispose();
  }
}
