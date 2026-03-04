import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:inscripcion_frontend/utils/time_formatter.dart';

class PdfGenerator {
  static Future<void> generateAndPrintBoleta({
    required Map<String, dynamic> data,
    required String carreraNombre,
    required String carreraCodigo,
  }) async {
    final pdf = pw.Document();

    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];

    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2026';
    final totalCreditos = materias.fold<int>(
        0, (sum, item) => sum + ((item['materia']?['creditos'] as int?) ?? 0));

    // Añadir página con el formato A4
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(nombrePeriodo),
            pw.SizedBox(height: 24),
            _buildStudentInfo(estudiante, carreraNombre, carreraCodigo),
            pw.SizedBox(height: 24),
            _buildTable(materias),
            pw.SizedBox(height: 24),
            _buildSummary(materias.length, totalCreditos),
          ];
        },
      ),
    );

    // Intentar mostrar o descargar el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Boleta_Inscripcion_${estudiante['registro'] ?? 'Alumno'}.pdf',
    );
  }

  static pw.Widget _buildHeader(String nombrePeriodo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#004b87'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Center(
        child: pw.Text(
          'BOLETA DE INSCRIPCIÓN - $nombrePeriodo',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildStudentInfo(
      Map<String, dynamic> estudiante, String carreraNombre, String carreraCodigo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('REGISTRO', estudiante['registro']?.toString() ?? ''),
          _buildInfoItem('NOMBRE', estudiante['nombreCompleto'] ?? ''),
          _buildInfoItem('CARRERA', '$carreraCodigo $carreraNombre'),
          _buildInfoItem('LUGAR', 'SANTA CRUZ'),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(List<dynamic> materias) {
    if (materias.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No hay materias inscritas',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
      );
    }

    final headers = [
      'SIGLA',
      'GRUPO',
      'NOMBRE MATERIA',
      'CRÉD',
      'SEM',
      'HORARIO',
      'MODALIDAD'
    ];

    final data = materias.map((item) {
      final materia = item['materia'] as Map<String, dynamic>? ?? {};
      final oferta = item['oferta'] as Map<String, dynamic>? ?? {};
      return [
        materia['codigo']?.toString() ?? '',
        oferta['grupo'] ?? item['grupo']?.toString() ?? '',
        materia['nombre']?.toString() ?? '',
        materia['creditos']?.toString() ?? '',
        oferta['semestre']?.toString() ?? '0',
        TimeFormatter.formatHorario(oferta['horario']?.toString() ?? ''),
        'PRESENCIAL',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#004b87'),
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FixedColumnWidth(45),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(35),
        4: const pw.FixedColumnWidth(30),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FixedColumnWidth(70),
      },
    );
  }

  static pw.Widget _buildSummary(int totalMaterias, int totalCreditos) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryData('Materias inscritas', totalMaterias.toString()),
          _buildSummaryData('Créditos totales', totalCreditos.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryData(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#004b87'),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
}
