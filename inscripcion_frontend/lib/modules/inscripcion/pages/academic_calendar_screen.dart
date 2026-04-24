import 'package:flutter/foundation.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';
import 'package:inscripcion_frontend/shared/utils/pdf_generator.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  bool _landscape = false;

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
    final provider = Provider.of<RegistrationProvider>(context);
    
    return MainLayout(
      title: 'Calendario Académico',
      subtitle: 'Consulta las fechas clave del semestre actual',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildCalendarCard(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(RegistrationProvider provider) {
    final isMobileView = Responsive.isMobile(context);
    final Map<String, dynamic> estudiante = {
      'nombreCompleto': 'Estudiante UAGRM',
      'registro': provider.studentRegister ?? '219005678',
    };
    final carreraNombre = provider.selectedCareer?.name ?? 'No especificada';
    final carreraCodigo = provider.selectedCareer?.code ?? 'N/A';
    final periodo = provider.selectedSemester ?? '1/2026 Semestre Regular';

    return AppTableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isMobileView 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: UAGRMTheme.sidebarBg, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Calendario Académico 2025',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: UAGRMTheme.sidebarBg,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildHeaderActions(
                          estudiante: estudiante,
                          carreraNombre: carreraNombre,
                          carreraCodigo: carreraCodigo,
                          periodo: periodo,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: UAGRMTheme.sidebarBg, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Calendario Académico 2025',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: UAGRMTheme.sidebarBg,
                              ),
                            ),
                          ],
                        ),
                        _buildHeaderActions(
                          estudiante: estudiante,
                          carreraNombre: carreraNombre,
                          carreraCodigo: carreraCodigo,
                          periodo: periodo,
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
          Builder(
            builder: (context) {
              final isMobileView = Responsive.isMobile(context);
              final labels = isMobileView 
                  ? const ['FECHA', 'EVENTO', 'TIPO']
                  : const ['FECHA', 'DÍA', 'EVENTO / ACTIVIDAD', 'TIPO'];
              final flexValues = isMobileView 
                  ? [2, 6, 3]
                  : [2, 2, 8, 3];

              return StandardTableContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StandardFlexHeader(
                      labels: labels,
                      flexValues: flexValues,
                    ),
                    ..._calendarEvents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final event = entry.value;
                      return StandardFlexRow(
                        flexValues: flexValues,
                        isLast: index == _calendarEvents.length - 1,
                        cells: [
                          tableText('${event['month']} ${event['day']}', isMobileView, bold: true),
                          if (!isMobileView)
                            tableText('Lunes', isMobileView),
                          tableText(event['title'], isMobileView),
                          AppProcessBadge(event['type'] ?? ''),
                        ],
                      );
                    }),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions({
    required Map<String, dynamic> estudiante,
    required String carreraNombre,
    required String carreraCodigo,
    required String periodo,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCompactButton(
          icon: _landscape ? Icons.stay_current_landscape : Icons.stay_current_portrait,
          label: _landscape ? 'HORIZONTAL' : 'VERTICAL',
          onTap: () => setState(() => _landscape = !_landscape),
          isActive: _landscape,
        ),
        ElevatedButton.icon(
          onPressed: () {
            PdfGenerator.generateAndPrintCalendario(
              _calendarEvents,
              landscape: _landscape,
              estudiante: estudiante,
              carreraNombre: carreraNombre,
              carreraCodigo: carreraCodigo,
              periodo: periodo,
            );
          },
          icon: const Icon(Icons.print, size: 16),
          label: const Text('IMPRIMIR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: UAGRMTheme.sidebarBg,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
  Widget _buildCompactButton({required IconData icon, required String label, required VoidCallback onTap, required bool isActive}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: isActive ? UAGRMTheme.sidebarBg.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: UAGRMTheme.sidebarBg),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: UAGRMTheme.sidebarBg, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
