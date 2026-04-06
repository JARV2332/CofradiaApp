import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../api/reporte_service.dart';

class ReporteCofradesScreen extends StatefulWidget {
  const ReporteCofradesScreen({Key? key}) : super(key: key);

  @override
  State<ReporteCofradesScreen> createState() => _ReporteCofradesScreenState();
}

class _ReporteCofradesScreenState extends State<ReporteCofradesScreen> {
  final ReporteService _reporteService = ReporteService();
  List<Map<String, dynamic>> _cofrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final cofrades = await _reporteService.getReporteCofrades();
      setState(() {
        _cofrades = cofrades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos: $e')),
        );
      }
    }
  }

  Future<void> _generarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte de Cofrades', 
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)
            )
          ),
          pw.Table.fromTextArray(
            context: context,
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 25,
            cellHeight: 40,
            headerStyle: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 10,
            ),
            headers: ['Nombre', 'Apellido', 'Sección', 'División', 'Teléfono', 'Correo'],
            data: _cofrades.map((cofrade) => [
              cofrade['nombre'],
              cofrade['apellido'],
              cofrade['seccion'],
              cofrade['division'],
              cofrade['telefono'],
              cofrade['correo'],
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Cofrades'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generarPDF,
            tooltip: 'Descargar PDF',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple.shade100],
          ),
        ),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : Card(
              margin: const EdgeInsets.all(16),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listado General de Cofrades',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.deepPurple.withOpacity(0.1)),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Apellido')),
                    DataColumn(label: Text('Sección')),
                    DataColumn(label: Text('División')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Correo')),
                  ],
                  rows: _cofrades.map(
                    (cofrade) => DataRow(
                      cells: [
                        DataCell(Text(cofrade['nombre'] ?? '')),
                        DataCell(Text(cofrade['apellido'] ?? '')),
                        DataCell(Text(cofrade['seccion'] ?? '')),
                        DataCell(Text(cofrade['division'] ?? '')),
                        DataCell(Text(cofrade['telefono'] ?? '')),
                        DataCell(Text(cofrade['correo'] ?? '')),
                      ],
                    ),
                  ).toList(),
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
}
