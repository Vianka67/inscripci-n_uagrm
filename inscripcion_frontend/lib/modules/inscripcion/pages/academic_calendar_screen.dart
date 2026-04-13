import 'package:flutter/foundation.dart';
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
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildCalendarCard(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(RegistrationProvider provider) {
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
                    Tooltip(
                      message: _landscape ? 'Cambiar a Vertical (Portrait)' : 'Cambiar a Horizontal (Landscape)',
                      child: InkWell(
                        onTap: () => setState(() => _landscape = !_landscape),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(8),
                            color: _landscape
                                ? UAGRMTheme.primaryBlue.withValues(alpha: 0.08)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _landscape ? Icons.stay_current_landscape : Icons.stay_current_portrait,
                                size: 18,
                                color: UAGRMTheme.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _landscape ? 'Horizontal' : 'Vertical',
                                style: const TextStyle(fontSize: 13, color: UAGRMTheme.primaryBlue, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
          AppTableHeader(
            children: const [
              SizedBox(width: 80, child: AppHeaderCell('Fecha')),
              SizedBox(width: 80, child: AppHeaderCell('Día')),
              Expanded(child: AppHeaderCell('Evento / Actividad')),
              SizedBox(width: 120, child: AppHeaderCell('Tipo', textAlign: TextAlign.center)),
            ],
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _calendarEvents.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) => _buildEventRow(_calendarEvents[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('${event['month']} ${event['day']}', style: const TextStyle(fontWeight: FontWeight.bold, color: UAGRMTheme.textDark, fontSize: 13))),
          const SizedBox(width: 80, child: Text('Lunes', style: TextStyle(color: UAGRMTheme.textGrey, fontSize: 13))),
          Expanded(child: Text(event['title'], style: const TextStyle(color: UAGRMTheme.textDark, fontSize: 13))),
          SizedBox(width: 120, child: AppProcessBadge(event['type'] ?? '')),
        ],
      ),
    );
  }
}
