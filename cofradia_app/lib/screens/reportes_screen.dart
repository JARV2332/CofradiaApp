import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cofrade.dart';
import '../models/evento.dart';
import '../services/api_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReporteAsistenciaRow {
  final String asistenciaId;
  final DateTime? fechaRegistro;
  final String estadoAsistencia;
  final String eventoId;
  final String eventoNombre;
  final String eventoFecha;
  final String cofradeId;
  final String cofradeNombreCompleto;
  final String seccion;
  final String division;
  final String agrupacion;

  _ReporteAsistenciaRow({
    required this.asistenciaId,
    required this.fechaRegistro,
    required this.estadoAsistencia,
    required this.eventoId,
    required this.eventoNombre,
    required this.eventoFecha,
    required this.cofradeId,
    required this.cofradeNombreCompleto,
    required this.seccion,
    required this.division,
    required this.agrupacion,
  });
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isExporting = false;

  List<Evento> _eventos = [];
  List<Cofrade> _cofrades = [];
  List<String> _secciones = [];
  List<String> _divisiones = [];
  List<String> _agrupaciones = [];
  List<_ReporteAsistenciaRow> _rows = [];

  DateTime? _desde;
  DateTime? _hasta;
  String? _eventoId;
  String? _cofradeId;
  String? _seccion;
  String? _division;
  String? _agrupacion;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      setState(() => _isLoading = true);
      final eventosFuture = _apiService.getEventos();
      final cofradesFuture = _apiService.getCofrades();
      final seccionesFuture = _apiService.getSeccionesCatalogo();
      final divisionesFuture = _apiService.getDivisionesCatalogo();
      final agrupacionesFuture = _apiService.getAgrupacionesCatalogo();

      _eventos = await eventosFuture;
      _cofrades = await cofradesFuture;
      _secciones = await seccionesFuture;
      _divisiones = await divisionesFuture;
      _agrupaciones = await agrupacionesFuture;

      await _loadReporte();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando catálogos de reportes: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReporte() async {
    try {
      setState(() => _isLoading = true);

      dynamic query = _supabase
          .from('asistencias')
          .select('id,evento_id,carnet_id,estado,created_at');

      if (_eventoId != null && _eventoId!.isNotEmpty) {
        query = query.eq('evento_id', _eventoId!);
      }
      if (_desde != null) {
        query = query.gte('created_at', _desde!.toIso8601String());
      }
      if (_hasta != null) {
        final hastaFinDia = DateTime(
          _hasta!.year,
          _hasta!.month,
          _hasta!.day,
          23,
          59,
          59,
        );
        query = query.lte('created_at', hastaFinDia.toIso8601String());
      }

      query = query.order('created_at', ascending: false);

      final asistencias = (await query) as List<dynamic>;
      if (asistencias.isEmpty) {
        if (!mounted) return;
        setState(() {
          _rows = [];
          _isLoading = false;
        });
        return;
      }

      final carnetIds = asistencias
          .map((e) => (e as Map<String, dynamic>)['carnet_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final eventoIds = asistencias
          .map((e) => (e as Map<String, dynamic>)['evento_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final carnetsRows = carnetIds.isEmpty
          ? <dynamic>[]
          : (await _supabase
                  .from('carnets')
                  .select('id,cofrade_id')
                  .inFilter('id', carnetIds))
              as List<dynamic>;
      final carnetToCofrade = <String, String>{};
      for (final row in carnetsRows) {
        final map = row as Map<String, dynamic>;
        final carnetId = map['id']?.toString() ?? '';
        final cofradeId = map['cofrade_id']?.toString() ?? '';
        if (carnetId.isNotEmpty && cofradeId.isNotEmpty) {
          carnetToCofrade[carnetId] = cofradeId;
        }
      }

      final cofradeIds = carnetToCofrade.values.toSet().toList();
      final cofradesRows = cofradeIds.isEmpty
          ? <dynamic>[]
          : (await _supabase
                  .from('cofrades')
                  .select('*')
                  .inFilter('id', cofradeIds))
              as List<dynamic>;
      final cofradeMap = <String, Map<String, dynamic>>{};
      for (final row in cofradesRows) {
        final map = row as Map<String, dynamic>;
        final id = map['id']?.toString() ?? '';
        if (id.isNotEmpty) cofradeMap[id] = map;
      }

      final eventosRows = eventoIds.isEmpty
          ? <dynamic>[]
          : (await _supabase
                  .from('eventos')
                  .select('id,nombre,fecha')
                  .inFilter('id', eventoIds))
              as List<dynamic>;
      final eventoMap = <String, Map<String, dynamic>>{};
      for (final row in eventosRows) {
        final map = row as Map<String, dynamic>;
        final id = map['id']?.toString() ?? '';
        if (id.isNotEmpty) eventoMap[id] = map;
      }

      final result = <_ReporteAsistenciaRow>[];
      for (final raw in asistencias) {
        final a = raw as Map<String, dynamic>;
        final asistenciaId = a['id']?.toString() ?? '';
        final eventoId = a['evento_id']?.toString() ?? '';
        final carnetId = a['carnet_id']?.toString() ?? '';
        final estadoAsistencia = a['estado']?.toString() ?? '';
        final fechaRegistroRaw = a['created_at']?.toString();
        final fechaRegistro = fechaRegistroRaw == null
            ? null
            : DateTime.tryParse(fechaRegistroRaw);

        final cofradeId = carnetToCofrade[carnetId] ?? '';
        final cofradeRaw = cofradeMap[cofradeId];
        final eventoRaw = eventoMap[eventoId];
        if (cofradeRaw == null || eventoRaw == null) continue;

        final seccion = (cofradeRaw['categoria'] ?? '').toString();
        final division = (cofradeRaw['estado'] ?? '').toString();
        final agrupacion = (cofradeRaw['agrupacion'] ?? '').toString();
        final cofradeNombre =
            '${(cofradeRaw['nombre'] ?? '').toString()} ${(cofradeRaw['apellidos'] ?? '').toString()}'
                .trim();

        if (_cofradeId != null && _cofradeId != cofradeId) continue;
        if (_seccion != null && _seccion != seccion) continue;
        if (_division != null && _division != division) continue;
        if (_agrupacion != null && _agrupacion != agrupacion) continue;

        result.add(
          _ReporteAsistenciaRow(
            asistenciaId: asistenciaId,
            fechaRegistro: fechaRegistro,
            estadoAsistencia: estadoAsistencia,
            eventoId: eventoId,
            eventoNombre: (eventoRaw['nombre'] ?? '').toString(),
            eventoFecha: (eventoRaw['fecha'] ?? '').toString(),
            cofradeId: cofradeId,
            cofradeNombreCompleto: cofradeNombre,
            seccion: seccion,
            division: division,
            agrupacion: agrupacion,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _rows = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando reporte: $e')),
      );
    }
  }

  Future<void> _pickDate({required bool isDesde}) async {
    final initial = isDesde ? (_desde ?? DateTime.now()) : (_hasta ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDesde) {
        _desde = picked;
      } else {
        _hasta = picked;
      }
    });
    await _loadReporte();
  }

  Future<void> _exportarPdf() async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
      final now = dateFmt.format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text(
              'Reporte de Asistencias',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generado: $now'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Filtros: '
              'Desde=${_desde == null ? "Todos" : DateFormat('yyyy-MM-dd').format(_desde!)} | '
              'Hasta=${_hasta == null ? "Todos" : DateFormat('yyyy-MM-dd').format(_hasta!)} | '
              'Actividad=${_labelEvento(_eventoId) ?? "Todas"} | '
              'Cofrade=${_labelCofrade(_cofradeId) ?? "Todos"} | '
              'Sección=${_seccion ?? "Todas"} | División=${_division ?? "Todas"} | Agrupación=${_agrupacion ?? "Todas"}',
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Fecha registro',
                'Actividad',
                'Fecha evento',
                'Cofrade',
                'Sección',
                'División',
                'Agrupación',
                'Estado',
              ],
              data: _rows.map((r) {
                return [
                  r.fechaRegistro == null ? '' : dateFmt.format(r.fechaRegistro!),
                  r.eventoNombre,
                  r.eventoFecha,
                  r.cofradeNombreCompleto,
                  r.seccion,
                  r.division,
                  r.agrupacion,
                  r.estadoAsistencia,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: const {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
                6: pw.Alignment.centerLeft,
                7: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String? _labelEvento(String? id) {
    if (id == null) return null;
    for (final evento in _eventos) {
      if (evento.id == id) return evento.nombre;
    }
    return null;
  }

  String? _labelCofrade(String? id) {
    if (id == null) return null;
    for (final cofrade in _cofrades) {
      if (cofrade.id == id) return '${cofrade.nombre} ${cofrade.apellidos}'.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReporte,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportarPdf,
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isDesde: true),
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _desde == null
                              ? 'Desde'
                              : 'Desde: ${DateFormat('yyyy-MM-dd').format(_desde!)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isDesde: false),
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _hasta == null
                              ? 'Hasta'
                              : 'Hasta: ${DateFormat('yyyy-MM-dd').format(_hasta!)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _eventoId,
                          decoration: const InputDecoration(labelText: 'Actividad'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._eventos.map(
                              (evento) => DropdownMenuItem<String>(
                                value: evento.id,
                                child: Text(evento.nombre),
                              ),
                            ),
                          ],
                          onChanged: (value) async {
                            setState(() => _eventoId = value);
                            await _loadReporte();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          value: _cofradeId,
                          decoration: const InputDecoration(labelText: 'Cofrade'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._cofrades.map(
                              (cofrade) => DropdownMenuItem<String>(
                                value: cofrade.id,
                                child: Text('${cofrade.nombre} ${cofrade.apellidos}'.trim()),
                              ),
                            ),
                          ],
                          onChanged: (value) async {
                            setState(() => _cofradeId = value);
                            await _loadReporte();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                          value: _seccion,
                          decoration: const InputDecoration(labelText: 'Sección'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Todas')),
                            ..._secciones.map(
                              (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
                            ),
                          ],
                          onChanged: (value) async {
                            setState(() => _seccion = value);
                            await _loadReporte();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                          value: _division,
                          decoration: const InputDecoration(labelText: 'División'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Todas')),
                            ..._divisiones.map(
                              (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
                            ),
                          ],
                          onChanged: (value) async {
                            setState(() => _division = value);
                            await _loadReporte();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<String>(
                          value: _agrupacion,
                          decoration: const InputDecoration(labelText: 'Agrupación'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Todas')),
                            ..._agrupaciones.map(
                              (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
                            ),
                          ],
                          onChanged: (value) async {
                            setState(() => _agrupacion = value);
                            await _loadReporte();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _desde = null;
                            _hasta = null;
                            _eventoId = null;
                            _cofradeId = null;
                            _seccion = null;
                            _division = null;
                            _agrupacion = null;
                          });
                          await _loadReporte();
                        },
                        child: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _rows.isEmpty
                      ? const Center(child: Text('No hay datos para los filtros seleccionados'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Fecha registro')),
                                DataColumn(label: Text('Actividad')),
                                DataColumn(label: Text('Fecha evento')),
                                DataColumn(label: Text('Cofrade')),
                                DataColumn(label: Text('Sección')),
                                DataColumn(label: Text('División')),
                                DataColumn(label: Text('Agrupación')),
                                DataColumn(label: Text('Estado')),
                              ],
                              rows: _rows.map((r) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        r.fechaRegistro == null
                                            ? ''
                                            : DateFormat('yyyy-MM-dd HH:mm')
                                                .format(r.fechaRegistro!),
                                      ),
                                    ),
                                    DataCell(Text(r.eventoNombre)),
                                    DataCell(Text(r.eventoFecha)),
                                    DataCell(Text(r.cofradeNombreCompleto)),
                                    DataCell(Text(r.seccion)),
                                    DataCell(Text(r.division)),
                                    DataCell(Text(r.agrupacion)),
                                    DataCell(Text(r.estadoAsistencia)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
