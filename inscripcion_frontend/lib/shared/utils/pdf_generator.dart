import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:inscripcion_frontend/shared/utils/time_formatter.dart';

class PdfGenerator {
  static Future<void> generateAndPrintBoleta({
    required Map<String, dynamic> data,
    required String carreraNombre,
    required String carreraCodigo,
  }) async {
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];

    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2026';
    final totalCreditos = materias.fold<int>(
        0, (sum, item) => sum + ((item['materia']?['creditos'] as int?) ?? 0));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();

        final docColors = {
          'textDark': PdfColor.fromHex('#0b1a2b'), // UAGRMTheme.textDark
          'textGrey': PdfColor.fromHex('#475569'),
          'border': PdfColor.fromHex('#e2e8f0'),
        };

        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              final w = format.availableWidth;
              final h = format.availableHeight;
              final isLandscape = w > h;
              
              final titleSize = isLandscape ? 18.0 : 16.0;
              final subSize   = isLandscape ? 10.0 : 9.0;
              final bodySize  = isLandscape ? 10.0 : 9.0;
              final tableSize = isLandscape ? 10.0 : 8.0;
              
              final headerBg = PdfColor.fromHex('#0b1a2b');

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── Encabezado ──────────────────────────────────────
                  pw.Center(child: pw.Text('Universidad Autónoma Gabriel René Moreno',
                      style: pw.TextStyle(color: docColors['textGrey'], fontSize: subSize))),
                  pw.SizedBox(height: 3),
                  pw.Center(child: pw.Text('BOLETA DE INSCRIPCIÓN',
                      style: pw.TextStyle(color: docColors['textDark'], fontSize: titleSize, fontWeight: pw.FontWeight.bold))),
                  pw.SizedBox(height: 3),
                  pw.Center(child: pw.Text('Periodo: $nombrePeriodo',
                      style: pw.TextStyle(color: docColors['textGrey'], fontSize: subSize))),
                  pw.SizedBox(height: isLandscape ? 12 : 16),

                  // ── Datos del estudiante ─────────────────────────────
                  pw.Row(children: [
                    pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      _infoRow('Estudiante', estudiante['nombreCompleto'] ?? '', bodySize, docColors),
                      pw.SizedBox(height: 6),
                      _infoRow('Carrera', '$carreraCodigo $carreraNombre', bodySize, docColors),
                    ])),
                    pw.SizedBox(width: 24),
                    pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      _infoRow('Registro', estudiante['registro']?.toString() ?? '', bodySize, docColors),
                      pw.SizedBox(height: 6),
                      _infoRow('CI', '(Sin registrar)', bodySize, docColors),
                    ])),
                  ]),
                  pw.SizedBox(height: isLandscape ? 10 : 14),
                  pw.Divider(color: docColors['border'], thickness: 0.8),
                  pw.SizedBox(height: isLandscape ? 8 : 12),

                  // ── Tabla con encabezado azul oscuro ─────────────────
                  _buildBoletaTable(materias, docColors, tableSize, headerBg),

                  pw.SizedBox(height: isLandscape ? 10 : 14),
                  pw.Center(child: pw.Text(
                    'Total de materias inscritas: ${materias.length}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: bodySize, color: docColors['textDark']),
                  )),
                ],
              );
            },
          ),
        );
        return pdf.save();
      },
      name: 'Boleta_Inscripcion_${estudiante['registro'] ?? 'Alumno'}.pdf',
    );
  }

  // Helper para fila de información
  static pw.Widget _infoRow(String label, String value, double fontSize, Map<String, PdfColor> colors) {
    return pw.RichText(text: pw.TextSpan(children: [
      pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize, color: colors['textDark'])),
      pw.TextSpan(text: value, style: pw.TextStyle(fontSize: fontSize, color: colors['textDark'])),
    ]));
  }

  // ── Tabla de la boleta (encabezado azul, texto blanco) ────────────────
  static pw.Widget _buildBoletaTable(List<dynamic> materias, Map<String, PdfColor> colors, double fontSize, PdfColor headerBg) {
    if (materias.isEmpty) {
      return pw.Center(child: pw.Text('No hay materias inscritas',
          style: pw.TextStyle(fontSize: fontSize, color: colors['textGrey']!)));
    }

    final headers = ['Nro', 'Sigla', 'Materia', 'Grupo', 'Docente', 'Horario', 'Aula'];
    final headerStyle = pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: fontSize);
    final cellStyle   = pw.TextStyle(fontSize: fontSize, color: PdfColors.black);

    final data = <List<String>>[];
    for (int i = 0; i < materias.length; i++) {
      final item   = materias[i];
      final mat    = item['materia'] as Map<String, dynamic>? ?? {};
      final oferta = item['oferta']  as Map<String, dynamic>? ?? {};
      data.add([
        (i + 1).toString(),
        mat['codigo']?.toString() ?? '',
        mat['nombre']?.toString() ?? '',
        oferta['grupo'] ?? item['grupo']?.toString() ?? '',
        oferta['docente']?.toString() ?? 'Por Asignar',
        TimeFormatter.formatHorario(oferta['horario']?.toString() ?? ''),
        'Aula ${101 + i}',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: headerStyle,
      headerDecoration: pw.BoxDecoration(color: headerBg),
      cellStyle: cellStyle,
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),   // Nro
        1: const pw.FlexColumnWidth(1.5),   // Sigla
        2: const pw.FlexColumnWidth(3.5),   // Materia
        3: const pw.FlexColumnWidth(0.8),   // Grupo
        4: const pw.FlexColumnWidth(2.5),   // Docente
        5: const pw.FlexColumnWidth(2.5),   // Horario
        6: const pw.FlexColumnWidth(1.2),   // Aula
      },
    );
  }

  // Keep old name for backward compat
  static pw.Widget _buildCleanTable(List<dynamic> materias, Map<String, PdfColor> colors, [double fontSize = 10]) {
    return _buildBoletaTable(materias, colors, fontSize, PdfColor.fromHex('#0b1a2b'));
  }

  // ============== BOLETA GRÁFICA ==============

  static Future<void> generateAndPrintBoletaGrafica({
    required Map<String, dynamic> data,
    required String carreraNombre,
    required String carreraCodigo,
  }) async {
    final materias   = data['materiasInscritas'] as List<dynamic>? ?? [];
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(16),
            build: (pw.Context context) {
              final w = format.availableWidth;
              final h = format.availableHeight;
              final isLandscape = w > h;
              final titleSize   = isLandscape ? 16.0 : 18.0;
              final subSize     = isLandscape ? 9.0  : 10.0;
              // Reserve tighter space for title + legend
              final headerH = subSize + titleSize + 20; // sub + title + margins
              const legendH = 24.0;
              const gap     = 10.0;
              final gridH   = h - headerH - legendH - gap;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Center(child: pw.Text('Universidad Autónoma Gabriel René Moreno',
                      style: pw.TextStyle(fontSize: subSize, color: PdfColors.grey700))),
                  pw.SizedBox(height: 3),
                  pw.Center(child: pw.Text('BOLETA GRÁFICA',
                      style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold))),
                  pw.SizedBox(height: 6),
                  // Grid fills ALL remaining width × height
                  pw.SizedBox(
                    width: w,
                    height: gridH > 0 ? gridH : 400,
                    child: _buildGraphicGrid(materias, w, gridH > 0 ? gridH : 400),
                  ),
                  pw.SizedBox(height: 4),
                  _buildGraphicLegend(materias),
                ],
              );
            },
          ),
        );
        return pdf.save();
      },
      name: 'Boleta_Grafica_${estudiante['registro'] ?? 'Alumno'}.pdf',
    );
  }

  static pw.Widget _buildGraphicGrid(List<dynamic> materias, [double gridWidth = 500, double gridHeight = 400]) {
    const days = ['Hora', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'];
    const timeSlots = [
      '07:00','08:00','09:00','10:00','11:00','12:00','13:00',
      '14:00','15:00','16:00','17:00','18:00','19:00','20:00','21:00'
    ];

    final dayIndex = {'L': 0, 'M': 1, 'I': 2, 'J': 3, 'V': 4, 'S': 5};
    final colorPalette = [
      PdfColor.fromHex('#4CAF50'), // Green
      PdfColor.fromHex('#2196F3'), // Blue
      PdfColor.fromHex('#FF9800'), // Orange
      PdfColor.fromHex('#9C27B0'), // Purple
      PdfColor.fromHex('#E91E63'), // Pink
      PdfColor.fromHex('#009688'), // Teal
      PdfColor.fromHex('#795548'), // Brown
      PdfColor.fromHex('#607D8B'), // Blue Grey
    ];

    final colorMap = <String, PdfColor>{};
    int colorIdx = 0;
    
    // gridData[dia][horaSlot] = {'codigo': ..., 'grupo': ...}
    Map<int, Map<int, Map<String, String>>> gridData = {};

    for (var item in materias) {
      final materiaObj = item['materia'] as Map<String, dynamic>? ?? {};
      final ofertaObj = item['oferta'] as Map<String, dynamic>? ?? {};
      final sigla = materiaObj['codigo']?.toString() ?? '';
      final grupo = item['grupo']?.toString() ?? ofertaObj['grupo']?.toString() ?? '';
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
          final hoursStr = startRaw.length >= 4 ? startRaw.substring(0, 2) : startRaw.substring(0, 1);
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
    // Calcular altura de fila dinámicamente para llenar el espacio disponible
    final rowHeight = (gridHeight / (timeSlots.length + 1)).clamp(12.0, 999.0);
    final fontSize = (rowHeight * 0.38).clamp(5.0, 13.0);
    final horaColWidth = (gridWidth * 0.09).clamp(24.0, 60.0);

    final tableData = <List<pw.Widget>>[];

    // Header Row
    final headerRow = days.map((d) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(4),
        color: PdfColors.grey200,
        child: pw.Center(
          child: pw.Text(d, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: (gridHeight / timeSlots.length * 0.35).clamp(7.0, 11.0))),
        ),
      );
    }).toList();
    tableData.add(headerRow);

    // Data Rows
    for (int t = 0; t < timeSlots.length; t++) {
      final row = <pw.Widget>[
        // Hora cell
        pw.Container(
          padding: const pw.EdgeInsets.all(3),
          color: PdfColors.grey100,
          child: pw.Center(
            child: pw.Text(timeSlots[t], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
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
                    pw.Text(code, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
                    pw.Text(cellData['grupo']!, style: pw.TextStyle(color: PdfColors.white, fontSize: (fontSize * 0.85).clamp(5.0, 9.0))),
                  ],
                ),
              ),
            ),
          );
        } else {
          row.add(pw.Container(padding: const pw.EdgeInsets.all(6))); // empty cell
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
          children: rowWidgets.map((cell) => pw.SizedBox(height: rowHeight, child: cell)).toList(),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildGraphicLegend(List<dynamic> materias) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 4,
      children: materias.map((item) {
        final materiaObj = item['materia'] as Map<String, dynamic>? ?? {};
        final sigla = materiaObj['codigo']?.toString() ?? '';
        final nombre = materiaObj['nombre']?.toString() ?? '';
        if (sigla.isEmpty) return pw.SizedBox();

        return pw.Text('$sigla - $nombre', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));
      }).toList(),
    );
  }

  // ============== CALENDARIO ACADÉMICO ==============

  static Future<void> generateAndPrintCalendario(List<Map<String, dynamic>> eventos) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#0b1a2b'), // Navy
                      borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CALENDARIO ACADÉMICO 2025', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Universidad Autónoma Gabriel René Moreno', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.TableHelper.fromTextArray(
                    headers: ['FECHA', 'DÍA', 'EVENTO / ACTIVIDAD', 'TIPO'],
                    data: eventos.map((e) => [
                      '${e['month']} ${e['day']}',
                      'Lunes', // placeholder since mock data doesn't have exact DOW
                      e['title'] ?? '',
                      e['type'] ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(color: PdfColor.fromHex('#0b1a2b'), fontWeight: pw.FontWeight.bold, fontSize: 10),
                    headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#EFF6FF')),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellAlignment: pw.Alignment.centerLeft,
                    rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                    cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(80),
                      1: const pw.FixedColumnWidth(60),
                      2: const pw.FlexColumnWidth(3),
                      3: const pw.FixedColumnWidth(80),
                    },
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
