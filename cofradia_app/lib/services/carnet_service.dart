import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart' as barcode;
import '../models/cofrade.dart';

class CarnetService {
  static Future<void> generarCarnet(Cofrade cofrade, BuildContext context) async {
    try {
      print('Iniciando generación de carnet para ${cofrade.nombre}');

      // 1) Crear carnet en Supabase para obtener el ID real (UUID) que irá en el QR.
      final supabase = Supabase.instance.client;
      final carnetRow = await supabase
          .from('carnets')
          .insert({
            'cofrade_id': cofrade.id,
            'active': true,
          })
          .select('id')
          .maybeSingle();

      if (carnetRow == null || carnetRow['id'] == null) {
        throw Exception('No se pudo crear el carnet en Supabase');
      }

      final carnetId = carnetRow['id'].toString();
      
      // 2) Generar PDF del carnet (foto + QR con solo carnetId)
      final pdf = await _crearCarnetPDFSimple(cofrade, carnetId);
      
      print('PDF creado exitosamente');
      
      // Abrir directamente en nueva pestaña
      await _abrirCarnetEnNuevaPestana(pdf, cofrade, context);
      
      print('Carnet abierto en nueva pestaña');
    } catch (e) {
      print('Error detallado al generar carnet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar carnet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Primero Storage con el cliente (misma API que la app → sin CORS en web), luego HTTP.
  static Future<Uint8List?> _cargarFotoCofrade(String url) async {
    final u = url.trim();
    if (u.isEmpty) return null;
    final desdeStorage = await _descargarFotoCofradeDesdeStorage(u);
    if (desdeStorage != null && desdeStorage.isNotEmpty) {
      return desdeStorage;
    }
    try {
      final r = await http.get(Uri.parse(u));
      if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
        return r.bodyBytes;
      }
    } catch (e) {
      debugPrint('Carnet: HTTP foto falló ($e)');
    }
    return null;
  }

  /// Si la URL falla, intenta los objetos habituales en el bucket por UUID del cofrade.
  static Future<Uint8List?> _descargarFotoCofradePorId(String cofradeId) async {
    if (cofradeId.isEmpty) return null;
    final bucket = Supabase.instance.client.storage.from('cofrade-fotos');
    for (final name in ['foto.jpeg', 'foto.jpg', 'foto.png']) {
      try {
        final bytes = await bucket.download('$cofradeId/$name');
        if (bytes.isNotEmpty) return bytes;
      } catch (_) {}
    }
    return null;
  }

  /// Construye un [pw.ImageProvider] que el paquete pdf pueda incrustar (JPEG directo o PNG re-codificado).
  static pw.ImageProvider? _proveedorImagenPdf(Uint8List bytes) {
    try {
      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint('Carnet: MemoryImage JPEG falló ($e), re-codificando…');
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      try {
        return pw.MemoryImage(img.encodePng(decoded));
      } catch (e2) {
        debugPrint('Carnet: PNG tampoco: $e2');
        return null;
      }
    }
  }

  /// Ruta del objeto dentro del bucket a partir de la URL pública de Supabase Storage.
  static String? _pathCofradeFotoDesdeUrl(String url) {
    const marker = '/object/public/cofrade-fotos/';
    final i = url.indexOf(marker);
    if (i >= 0) {
      final p = Uri.decodeComponent(url.substring(i + marker.length).split('?').first);
      return p.isEmpty ? null : p;
    }
    // Variantes de URL (p. ej. sin /storage/v1 o redirecciones)
    const tail = 'cofrade-fotos/';
    final j = url.lastIndexOf(tail);
    if (j >= 0) {
      final p = Uri.decodeComponent(url.substring(j + tail.length).split('?').first);
      return p.isEmpty ? null : p;
    }
    return null;
  }

  /// Si la URL apunta al bucket, descarga con el cliente (útil si falla HTTP/CORS en web).
  static Future<Uint8List?> _descargarFotoCofradeDesdeStorage(String url) async {
    final path = _pathCofradeFotoDesdeUrl(url);
    if (path == null) return null;
    try {
      return await Supabase.instance.client.storage
          .from('cofrade-fotos')
          .download(path);
    } catch (e) {
      debugPrint('Carnet: descarga Storage falló: $e');
      return null;
    }
  }

  static Future<pw.Document> _crearCarnetPDFSimple(Cofrade cofrade, String carnetId) async {
    try {
      print('Creando PDF simple para ${cofrade.nombre}');
      
      final pdf = pw.Document();
      var fotoBytes = await _cargarFotoCofrade(cofrade.fotoUrl);
      fotoBytes ??= await _descargarFotoCofradePorId(cofrade.id);
      final fotoPdf = fotoBytes != null ? _proveedorImagenPdf(fotoBytes) : null;

      // Generar QR code como widget (solo carnetId)
      final qrWidget = _generarQRWidget(carnetId);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              width: 350,
              height: 220,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 3, color: PdfColor.fromHex('#1565C0')), // Azul cofradía
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                children: [
                  // Encabezado del carnet con colores de cofradía
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [
                          PdfColor.fromHex('#1565C0'), // Azul cofradía
                          PdfColor.fromHex('#42A5F5'), // Azul claro
                        ],
                      ),
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(9),
                        topRight: pw.Radius.circular(9),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'COFRADÍA',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#FFD700'), // Amarillo cofradía
                            fontSize: 16,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'CARNET DE MIEMBRO',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido principal
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        // Foto del cofrade con colores de cofradía
                        pw.Container(
                          width: 80,
                          height: 100,
                          margin: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 2, color: PdfColor.fromHex('#D32F2F')), // Rojo cofradía
                            color: PdfColor.fromHex('#FFF9C4'), // Amarillo muy claro de fondo
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: fotoPdf != null
                              ? pw.ClipRRect(
                                  horizontalRadius: 6,
                                  verticalRadius: 6,
                                  child: pw.Image(
                                    fotoPdf,
                                    width: 80,
                                    height: 100,
                                    fit: pw.BoxFit.cover,
                                  ),
                                )
                              : pw.Center(
                                  child: pw.Text(
                                    cofrade.avatar,
                                    style: pw.TextStyle(
                                      fontSize: 28,
                                      color: PdfColor.fromHex('#1565C0'), // Azul cofradía
                                    ),
                                  ),
                                ),
                        ),
                        
                        // Información del cofrade con estilo de cofradía
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '${cofrade.nombre} ${cofrade.apellidos}',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    color: PdfColor.fromHex('#1565C0'), // Azul cofradía
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Sección: ${cofrade.categoria}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColor.fromHex('#1565C0'),
                                  ),
                                ),
                                pw.Text(
                                  'División: ${cofrade.estado}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColor.fromHex('#1565C0'),
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text('Email: ${cofrade.email}', style: const pw.TextStyle(fontSize: 10)),
                                pw.Text('Teléfono: ${cofrade.telefono}', style: const pw.TextStyle(fontSize: 10)),
                                pw.Text('Fecha Alta: ${cofrade.fechaAlta}', style: const pw.TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                        
                        // QR Code con marco de cofradía
                        pw.Container(
                          width: 75,
                          height: 75,
                          margin: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 2, color: PdfColor.fromHex('#FFD700')), // Amarillo cofradía
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: qrWidget ?? pw.Container(
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.grey),
                                    ),
                                    child: pw.Center(
                                      child: pw.Text('QR', style: const pw.TextStyle(fontSize: 12)),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pie del carnet
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(8),
                        bottomRight: pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Text(
                      'Documento de identificación · Cofradía',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      
      print('PDF generado exitosamente');
      return pdf;
    } catch (e) {
      print('Error creando PDF: $e');
      rethrow;
    }
  }

  static pw.Widget? _generarQRWidget(String carnetId) {
    try {
      return pw.BarcodeWidget(
        barcode: barcode.Barcode.qrCode(),
        data: carnetId,
        width: 70,
        height: 70,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> _abrirCarnetEnNuevaPestana(pw.Document pdf, Cofrade cofrade, BuildContext context) async {
    try {
      print('Abriendo carnet en nueva pestaña para ${cofrade.nombre}');
      
      // Abrir directamente el PDF en una nueva pestaña del navegador
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        format: PdfPageFormat.a4,
        name: 'Carnet_${cofrade.nombre}_${cofrade.apellidos}',
      );
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carnet abierto en nueva pestaña para ${cofrade.nombre}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error al abrir carnet en nueva pestaña: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir carnet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}