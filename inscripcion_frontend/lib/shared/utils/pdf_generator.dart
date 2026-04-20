import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:inscripcion_frontend/shared/utils/time_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Configuración de layout adaptable por orientación
//
//  En lugar de depender de `format.availableWidth/Height` dentro del callback
//  (que refleja el formato de la IMPRESORA, no el formato solicitado), pre-
//  calculamos todas las medidas a partir del parámetro `landscape`.  Esto
//  garantiza que el diseño es determinístico tanto en portrait como landscape.
// ─────────────────────────────────────────────────────────────────────────────
class _PdfLayout {
  // PÁGINA
  final PdfPageFormat pageFormat;
  final pw.EdgeInsets margin;

  // ── Ancho de contenido neto (pageFormat - márgenes) ────────────────────────
  final double contentWidth;  // px
  final double contentHeight; // px

  // ── Tipografía ─────────────────────────────────────────────────────────────
  final double titleSize;
  final double subSize;
  final double bodySize;
  final double tableSize;

  // ── Espaciados ─────────────────────────────────────────────────────────────
  final double vGapSM;
  final double vGapMD;

  // ── Bandera de orientación ─────────────────────────────────────────────────
  final bool isLandscape;

  const _PdfLayout({
    required this.pageFormat,
    required this.margin,
    required this.contentWidth,
    required this.contentHeight,
    required this.titleSize,
    required this.subSize,
    required this.bodySize,
    required this.tableSize,
    required this.vGapSM,
    required this.vGapMD,
    required this.isLandscape,
  });

  /// Fábrica basada en formato de System Spooler
  factory _PdfLayout.fromFormat(PdfPageFormat format) {
    final bool landscape = format.width > format.height;
    final double mH = landscape ? 24.0 : 40.0;
    final double mV = landscape ? 18.0 : 28.0;
    return _PdfLayout(
      pageFormat: format,
      margin: pw.EdgeInsets.symmetric(horizontal: mH, vertical: mV),
      contentWidth: (format.width - mH * 2).clamp(1.0, 9999.0),
      contentHeight: (format.height - mV * 2).clamp(1.0, 9999.0),
      titleSize: landscape ? 16.0 : 15.0,
      subSize: 9.0,
      bodySize: landscape ? 9.5 : 9.0,
      tableSize: landscape ? 9.0 : 8.0,
      vGapSM: landscape ? 6.0 : 8.0,
      vGapMD: landscape ? 10.0 : 14.0,
      isLandscape: landscape,
    );
  }

  /// Fábrica: construye el layout para la orientación pedida.
  factory _PdfLayout.from({required bool landscape}) {
    // A4 en puntos: 595.28 × 841.89 pt
    const double a4W = 595.28;
    const double a4H = 841.89;

    final double pageW = landscape ? a4H : a4W;
    final double pageH = landscape ? a4W : a4H;

    final double mH = landscape ? 24.0 : 40.0; // margen horizontal
    final double mV = landscape ? 18.0 : 28.0; // margen vertical

    return _PdfLayout(
      pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: pw.EdgeInsets.symmetric(horizontal: mH, vertical: mV),
      contentWidth: pageW - mH * 2,
      contentHeight: pageH - mV * 2,
      titleSize: landscape ? 16.0 : 15.0,
      subSize: 9.0,
      bodySize: landscape ? 9.5 : 9.0,
      tableSize: landscape ? 9.0 : 8.0,
      vGapSM: landscape ? 6.0 : 8.0,
      vGapMD: landscape ? 10.0 : 14.0,
      isLandscape: landscape,
    );
  }
}

class PdfGenerator {
  // ─────────────────────────────────────────────────────────────────────────
  //  BOLETA ESTÁNDAR
  // ─────────────────────────────────────────────────────────────────────────

  /// Genera e imprime la boleta de inscripción en formato estándar.
  ///
  /// [landscape] = false → A4 vertical (portrait).
  /// [landscape] = true  → A4 horizontal (landscape).
  static Future<void> generateAndPrintBoleta({
    required Map<String, dynamic> data,
    required String carreraNombre,
    required String carreraCodigo,
    bool landscape = false,
  }) async {
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];
    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2026';

    // Layout pre-calculado — independiente del printer driver
    final layout = _PdfLayout.from(landscape: landscape);

    final docColors = {
      'textDark': PdfColor.fromHex('#0b1a2b'),
      'textGrey': PdfColor.fromHex('#475569'),
      'border': PdfColor.fromHex('#e2e8f0'),
    };
    final headerBg = PdfColor.fromHex('#0b1a2b');

    await Printing.layoutPdf(
      format: layout.pageFormat,
      onLayout: (PdfPageFormat spoolerFormat) async {
        final dynamicLayout = _PdfLayout.fromFormat(spoolerFormat);
        final pdf = pw.Document();

        pdf.addPage(
          pw.Page(
            pageFormat: dynamicLayout.pageFormat,
            margin: dynamicLayout.margin,
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── Encabezado y Datos del Estudiante ──────────────────────
                _buildDocumentHeader(
                  titulo: 'BOLETA DE INSCRIPCIÓN',
                  periodo: nombrePeriodo,
                  estudiante: estudiante,
                  carreraCodigo: carreraCodigo,
                  carreraNombre: carreraNombre,
                  layout: dynamicLayout,
                  docColors: docColors,
                ),

                // ── Tabla de materias ────────────────────────────────────
                _buildBoletaTable(
                  materias,
                  docColors,
                  dynamicLayout.tableSize,
                  headerBg,
                  isLandscape: dynamicLayout.isLandscape,
                  contentWidth: dynamicLayout.contentWidth,
                ),

                pw.SizedBox(height: dynamicLayout.vGapSM),
                pw.Center(
                  child: pw.Text(
                    'Total de materias inscritas: ${materias.length}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: dynamicLayout.bodySize,
                        color: docColors['textDark']),
                  ),
                ),
              ],
            ),
          ),
        );
        return pdf.save();
      },
      name: 'Boleta_Inscripcion_${estudiante['registro'] ?? 'Alumno'}.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HELPERS — COMÚN (ENCABEZADO)
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildDocumentHeader({
    required String titulo,
    required String periodo,
    required Map<String, dynamic> estudiante,
    required String carreraCodigo,
    required String carreraNombre,
    required _PdfLayout layout,
    required Map<String, PdfColor> docColors,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'Universidad Autónoma Gabriel René Moreno',
            style: pw.TextStyle(color: docColors['textGrey'], fontSize: layout.subSize),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            titulo,
            style: pw.TextStyle(color: docColors['textDark'], fontSize: layout.titleSize, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'Periodo: $periodo',
            style: pw.TextStyle(color: docColors['textGrey'], fontSize: layout.subSize),
          ),
        ),
        pw.SizedBox(height: layout.vGapMD),
        pw.Row(children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _infoRow('Estudiante', estudiante['nombreCompleto'] ?? '', layout.bodySize, docColors),
              pw.SizedBox(height: 5),
              _infoRow('Carrera', '$carreraCodigo $carreraNombre', layout.bodySize, docColors),
            ]),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _infoRow('Registro', estudiante['registro']?.toString() ?? '', layout.bodySize, docColors),
              pw.SizedBox(height: 5),
              _infoRow('CI', '(Sin registrar)', layout.bodySize, docColors),
            ]),
          ),
        ]),
        pw.SizedBox(height: layout.vGapSM),
        pw.Divider(color: docColors['border'], thickness: 0.8),
        pw.SizedBox(height: layout.vGapSM),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HELPERS — BOLETA ESTÁNDAR
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _infoRow(
      String label, String value, double fontSize, Map<String, PdfColor> colors) {
    return pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: fontSize,
                color: colors['textDark'])),
        pw.TextSpan(
            text: value,
            style: pw.TextStyle(fontSize: fontSize, color: colors['textDark'])),
      ]),
    );
  }

  /// Tabla de materias con anchos adaptativos según orientación.
  ///
  /// Recibe [contentWidth] para poder ajustar la columna fija Nro
  /// proporcional al ancho real de la página (portrait vs landscape).
  static pw.Widget _buildBoletaTable(
    List<dynamic> materias,
    Map<String, PdfColor> colors,
    double fontSize,
    PdfColor headerBg, {
    bool isLandscape = false,
    double contentWidth = 500,
  }) {
    if (materias.isEmpty) {
      return pw.Center(
          child: pw.Text('No hay materias inscritas',
              style: pw.TextStyle(
                  fontSize: fontSize, color: colors['textGrey']!)));
    }

    final headers = ['Nro', 'Sigla', 'Materia', 'Grupo', 'Docente', 'Horario', 'Aula'];
    final headerStyle = pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: fontSize);
    final cellStyle = pw.TextStyle(fontSize: fontSize, color: PdfColors.black);

    final tableData = <List<String>>[];
    for (int i = 0; i < materias.length; i++) {
      final item = materias[i];
      final mat = item['materia'] as Map<String, dynamic>? ?? {};
      final oferta = item['oferta'] as Map<String, dynamic>? ?? {};
      tableData.add([
        (i + 1).toString(),
        mat['codigo']?.toString() ?? '',
        mat['nombre']?.toString() ?? '',
        oferta['grupo'] ?? item['grupo']?.toString() ?? '',
        oferta['docente']?.toString() ?? 'Por Asignar',
        TimeFormatter.formatHorario(oferta['horario']?.toString() ?? ''),
        'Aula ${101 + i}',
      ]);
    }

    // Columna fija Nro: proporcional al ancho total, ligeramente mayor en portrait
    final nroWidth = (contentWidth * (isLandscape ? 0.036 : 0.045)).clamp(22.0, 36.0);

    // En portrait, Materia y Docente son algo más compactas para que todo quepa
    final colWidths = isLandscape
        ? <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(nroWidth),  // Nro
            1: const pw.FlexColumnWidth(1.4),  // Sigla
            2: const pw.FlexColumnWidth(4.0),  // Materia
            3: const pw.FlexColumnWidth(0.8),  // Grupo
            4: const pw.FlexColumnWidth(3.0),  // Docente
            5: const pw.FlexColumnWidth(3.0),  // Horario
            6: const pw.FlexColumnWidth(1.2),  // Aula
          }
        : <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(nroWidth),
            1: const pw.FlexColumnWidth(1.5),  // Sigla
            2: const pw.FlexColumnWidth(3.2),  // Materia  ← compacta
            3: const pw.FlexColumnWidth(0.9),  // Grupo
            4: const pw.FlexColumnWidth(2.2),  // Docente  ← compacta
            5: const pw.FlexColumnWidth(2.6),  // Horario
            6: const pw.FlexColumnWidth(1.1),  // Aula
          };

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: tableData,
      headerStyle: headerStyle,
      headerDecoration: pw.BoxDecoration(color: headerBg),
      cellStyle: cellStyle,
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      cellPadding: pw.EdgeInsets.symmetric(
          vertical: isLandscape ? 5 : 6, horizontal: 4),
      columnWidths: colWidths,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BOLETA GRÁFICA
  // ─────────────────────────────────────────────────────────────────────────

  /// Genera e imprime la boleta gráfica (grilla horaria semanal).
  ///
  /// [landscape] = false → A4 vertical (portrait).
  /// [landscape] = true  → A4 horizontal (landscape).
  static Future<void> generateAndPrintBoletaGrafica({
    required Map<String, dynamic> data,
    required String carreraNombre,
    required String carreraCodigo,
    bool landscape = false,
  }) async {
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};

    final periodoInfo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final nombrePeriodo = periodoInfo['nombre'] ?? periodoInfo['codigo'] ?? '1/2026';

    final docColors = {
      'textDark': PdfColor.fromHex('#0b1a2b'),
      'textGrey': PdfColor.fromHex('#475569'),
      'border': PdfColor.fromHex('#e2e8f0'),
    };

    // Layout pre-calculado — determinístico
    final layout = _PdfLayout.from(landscape: landscape);

    await Printing.layoutPdf(
      format: layout.pageFormat,
      onLayout: (PdfPageFormat spoolerFormat) async {
        final dynamicLayout = _PdfLayout.fromFormat(spoolerFormat);
        final pdf = pw.Document();

        // Reservas verticales fijas
        final headerH = dynamicLayout.titleSize + dynamicLayout.subSize * 2 + dynamicLayout.vGapMD + dynamicLayout.vGapSM * 2 + 50.0;
        const legendLineH = 18.0;
        const gapBelowTitle = 6.0;
        const gapAboveLegend = 4.0;

        final legendLines = ((materias.length / 4) + 1).ceil().clamp(1, 4);
        final legendH = legendLineH * legendLines;

        final gridH = (dynamicLayout.contentHeight - headerH - legendH - gapBelowTitle - gapAboveLegend)
            .clamp(landscape ? 260.0 : 380.0, 9999.0);

        pdf.addPage(
          pw.Page(
            pageFormat: dynamicLayout.pageFormat,
            margin: dynamicLayout.margin,
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildDocumentHeader(
                  titulo: 'BOLETA GRÁFICA',
                  periodo: nombrePeriodo,
                  estudiante: estudiante,
                  carreraCodigo: carreraCodigo,
                  carreraNombre: carreraNombre,
                  layout: dynamicLayout,
                  docColors: docColors,
                ),

                // ── Grilla horaria ───────────────────────────────────────
                pw.SizedBox(
                  width: dynamicLayout.contentWidth,
                  height: gridH,
                  child: _buildGraphicGrid(
                    materias,
                    dynamicLayout.contentWidth,
                    gridH,
                  ),
                ),
                pw.SizedBox(height: gapAboveLegend),

                // ── Leyenda ──────────────────────────────────────────────
                _buildGraphicLegend(materias, dynamicLayout.subSize),
              ],
            ),
          ),
        );
        return pdf.save();
      },
      name: 'Boleta_Grafica_${estudiante['registro'] ?? 'Alumno'}.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HELPERS — BOLETA GRÁFICA
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildGraphicGrid(
      List<dynamic> materias,
      [double gridWidth = 500,
      double gridHeight = 400]) {
    const days = ['Hora', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    const timeSlots = [
      '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
      '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
    ];

    final dayIndex = {'L': 0, 'M': 1, 'I': 2, 'J': 3, 'V': 4, 'S': 5};
    final colorPalette = [
      PdfColor.fromHex('#4CAF50'),
      PdfColor.fromHex('#2196F3'),
      PdfColor.fromHex('#FF9800'),
      PdfColor.fromHex('#9C27B0'),
      PdfColor.fromHex('#E91E63'),
      PdfColor.fromHex('#009688'),
      PdfColor.fromHex('#795548'),
      PdfColor.fromHex('#607D8B'),
    ];

    final colorMap = <String, PdfColor>{};
    int colorIdx = 0;

    // gridData[dia][horaSlot] = {'codigo': ..., 'grupo': ...}
    Map<int, Map<int, Map<String, String>>> gridData = {};

    for (var item in materias) {
      final materiaObj = item['materia'] as Map<String, dynamic>? ?? {};
      final ofertaObj = item['oferta'] as Map<String, dynamic>? ?? {};
      final sigla = materiaObj['codigo']?.toString() ?? '';
      final grupo =
          item['grupo']?.toString() ?? ofertaObj['grupo']?.toString() ?? '';
      final horario = ofertaObj['horario']?.toString() ?? '';

      if (!colorMap.containsKey(sigla)) {
        colorMap[sigla] = colorPalette[colorIdx % colorPalette.length];
        colorIdx++;
      }

      if (horario.isEmpty) continue;

      final parts = horario.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final spaceIdx = trimmed.indexOf(' ');
        if (spaceIdx < 0) continue;

        final diasStr = trimmed.substring(0, spaceIdx).trim().toUpperCase();
        final horaStr = trimmed.substring(spaceIdx + 1).trim();
        final horaRange = horaStr.replaceAll(':', '');
        final dashIdx = horaRange.indexOf('-');
        if (dashIdx < 0) continue;

        final startRaw = horaRange.substring(0, dashIdx).trim();
        if (startRaw.length < 3) continue;

        int startHour;
        try {
          final hoursStr = startRaw.length >= 4
              ? startRaw.substring(0, 2)
              : startRaw.substring(0, 1);
          startHour = int.parse(hoursStr);
        } catch (_) {
          continue;
        }

        final slotKey = '${startHour.toString().padLeft(2, '0')}:00';
        final slotIdx = timeSlots.indexOf(slotKey);

        for (final dayChar in diasStr.split('')) {
          final dIdx = dayIndex[dayChar];
          if (dIdx == null) continue;

          gridData[dIdx] ??= {};
          gridData[dIdx]![slotIdx >= 0 ? slotIdx : startHour - 7] = {
            'codigo': sigla,
            'grupo': grupo,
          };
        }
      }
    }

    // Altura de cada fila: distribuir gridHeight entre (timeSlots + 1 encabezado)
    final rowHeight =
        (gridHeight / (timeSlots.length + 1)).clamp(12.0, 999.0);
    final fontSize = (rowHeight * 0.38).clamp(5.0, 11.0);
    // Columna "Hora": 9 % del ancho, entre 26 y 56 pt
    final horaColWidth = (gridWidth * 0.09).clamp(26.0, 56.0);

    final tableData = <List<pw.Widget>>[];

    // Fila de encabezados
    final headerFontSize = (rowHeight * 0.35).clamp(6.0, 10.0);
    final headerRow = days.map((d) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(3),
        color: PdfColors.grey200,
        child: pw.Center(
          child: pw.Text(d,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: headerFontSize)),
        ),
      );
    }).toList();
    tableData.add(headerRow);

    // Filas de datos
    for (int t = 0; t < timeSlots.length; t++) {
      final row = <pw.Widget>[
        pw.Container(
          padding: const pw.EdgeInsets.all(3),
          color: PdfColors.grey100,
          child: pw.Center(
            child: pw.Text(timeSlots[t],
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
          ),
        ),
      ];

      for (int d = 0; d < 6; d++) {
        final cellData = gridData[d]?[t];
        if (cellData != null) {
          final code = cellData['codigo']!;
          final bgColor = colorMap[code] ?? PdfColors.blue;
          row.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              color: bgColor,
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(code,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize)),
                    pw.Text(cellData['grupo']!,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: (fontSize * 0.85).clamp(4.5, 9.0))),
                  ],
                ),
              ),
            ),
          );
        } else {
          row.add(pw.Container(padding: const pw.EdgeInsets.all(4)));
        }
      }
      tableData.add(row);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: pw.FixedColumnWidth(horaColWidth),
        1: const pw.FlexColumnWidth(),
        2: const pw.FlexColumnWidth(),
        3: const pw.FlexColumnWidth(),
        4: const pw.FlexColumnWidth(),
        5: const pw.FlexColumnWidth(),
        6: const pw.FlexColumnWidth(),
      },
      children: tableData.map((rowWidgets) {
        return pw.TableRow(
          children: rowWidgets
              .map((cell) => pw.SizedBox(height: rowHeight, child: cell))
              .toList(),
        );
      }).toList(),
    );
  }

  /// Leyenda de colores con tamaño de fuente adaptable.
  static pw.Widget _buildGraphicLegend(
      List<dynamic> materias, [double fontSize = 9]) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 4,
      children: materias.map((item) {
        final materiaObj = item['materia'] as Map<String, dynamic>? ?? {};
        final sigla = materiaObj['codigo']?.toString() ?? '';
        final nombre = materiaObj['nombre']?.toString() ?? '';
        if (sigla.isEmpty) return pw.SizedBox();
        return pw.Text('$sigla - $nombre',
            style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey700));
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CALENDARIO ACADÉMICO
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> generateAndPrintCalendario(
      List<Map<String, dynamic>> eventos, {
      bool landscape = false,
      Map<String, dynamic> estudiante = const {},
      String carreraNombre = '',
      String carreraCodigo = '',
      String periodo = '1/2026 Semestre Regular',
  }) async {
    final layout = _PdfLayout.from(landscape: landscape);
    final finalFormat = layout.pageFormat;

    final docColors = {
      'textDark': PdfColor.fromHex('#0b1a2b'),
      'textGrey': PdfColor.fromHex('#475569'),
      'border': PdfColor.fromHex('#e2e8f0'),
    };

    await Printing.layoutPdf(
      format: layout.pageFormat,
      onLayout: (PdfPageFormat spoolerFormat) async {
        final dynamicLayout = _PdfLayout.fromFormat(spoolerFormat);
        final pdf = pw.Document();

        pdf.addPage(
          pw.Page(
            pageFormat: dynamicLayout.pageFormat,
            margin: dynamicLayout.margin,
            build: (pw.Context ctx) {
              final colWidths = dynamicLayout.isLandscape
                  ? {
                      0: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.15),
                      1: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.10),
                      2: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.60),
                      3: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.15),
                    }
                  : {
                      0: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.14),
                      1: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.10),
                      2: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.61),
                      3: pw.FixedColumnWidth(dynamicLayout.contentWidth * 0.15),
                    };
              
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                    _buildDocumentHeader(
                    titulo: 'CALENDARIO ACADÉMICO 2025',
                    periodo: periodo,
                    estudiante: estudiante,
                    carreraCodigo: carreraCodigo,
                    carreraNombre: carreraNombre,
                    layout: dynamicLayout,
                    docColors: docColors,
                  ),
                  pw.TableHelper.fromTextArray(
                    headers: ['FECHA', 'DÍA', 'EVENTO / ACTIVIDAD', 'TIPO'],
                    data: eventos
                        .map((e) => [
                              '${e['month']} ${e['day']}',
                              'Lunes',
                              e['title'] ?? '',
                              e['type'] ?? '',
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: dynamicLayout.tableSize + 1),
                    headerDecoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#0b1a2b')),
                    cellStyle: pw.TextStyle(fontSize: dynamicLayout.tableSize),
                    cellAlignment: pw.Alignment.centerLeft,
                    rowDecoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(
                                color: PdfColors.grey300, width: 0.5))),
                    cellPadding: pw.EdgeInsets.symmetric(
                        vertical: dynamicLayout.vGapSM, horizontal: 6),
                    columnWidths: colWidths,
                  ),
                ],
              );
            },
          ),
        );
        return pdf.save();
      },
      name: 'Calendario_Academico_2025.pdf',
    );
  }
}
