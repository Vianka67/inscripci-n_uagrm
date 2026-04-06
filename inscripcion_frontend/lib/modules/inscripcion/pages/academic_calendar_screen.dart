import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/utils/pdf_generator.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
    }
  }

  // Static Data as per the mock
  final List<Map<String, dynamic>> _calendarEvents = [
    {
      'month': 'feb',
      'day': '3',
      'title': 'Inicio de actividades académicas - Semestre 1/2025',
      'type': 'Académico',
    },
    {
      'month': 'feb',
      'day': '15',
      'title': 'Inscripción estudiantes antiguos',
      'type': 'Inscripción',
    },
    {
      'month': 'feb',
      'day': '25',
      'title': 'Período de adición de materias',
      'type': 'Inscripción',
    },
    {
      'month': 'mar',
      'day': '1',
      'title': 'Feriado - Día del Departamento',
      'type': 'Feriado',
    },
    {
      'month': 'mar',
      'day': '10',
      'title': 'Período de retiro de materias',
      'type': 'Inscripción',
    },
    {
      'month': 'abr',
      'day': '14',
      'title': 'Primer examen parcial',
      'type': 'Examen',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Calendario Académico',
      subtitle: 'Consulta las fechas clave del semestre actual',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildCalendarCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: UAGRMTheme.primaryBlue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Calendario Académico 2025',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UAGRMTheme.primaryBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        PdfGenerator.generateAndPrintCalendario(_calendarEvents);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Imprimir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UAGRMTheme.sidebarPanel,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Universidad Autónoma Gabriel René Moreno',
                  style: TextStyle(color: UAGRMTheme.textGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) => UAGRMTheme.sidebarDeep),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                dividerThickness: 0.5,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Día')),
                  DataColumn(label: Text('Evento / Actividad')),
                  DataColumn(label: Text('Tipo')),
                ],
                rows: _calendarEvents.map((event) => _buildEventRow(event)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildEventRow(Map<String, dynamic> event) {
    Color badgeColor;
    Color textColor;
    
    switch (event['type']) {
      case 'Académico':
        badgeColor = UAGRMTheme.sidebarPanel;
        textColor = Colors.white;
        break;
      case 'Examen':
        badgeColor = UAGRMTheme.primaryRed;
        textColor = Colors.white;
        break;
      default:
        badgeColor = const Color(0xFFF3F4F6); // Light grey
        textColor = const Color(0xFF4B5563); // Darker grey text
    }

    return DataRow(
      cells: [
        DataCell(Text('${event['month']} ${event['day']}', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text('Lunes')), // We can improve this with actual date parsing if needed
        DataCell(Text(event['title'])),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              event['type'],
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
