import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/time_formatter.dart';
import 'package:inscripcion_frontend/shared/utils/pdf_generator.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/modules/inscripcion/widgets/schedule_grid_view.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';

class EnrollmentSlipScreen extends StatefulWidget {
  const EnrollmentSlipScreen({super.key});

  @override
  State<EnrollmentSlipScreen> createState() => _EnrollmentSlipScreenState();
}

class _EnrollmentSlipScreenState extends State<EnrollmentSlipScreen> {
  // Periodo seleccionado (null = periodo actual/más reciente)
  String? selectedPeriodCodigo;
  int _currentTabIndex = 0;   // 0 = Normal, 1 = Gráfica
  bool _landscape = false;    // false = portrait (vertical), true = landscape (horizontal)

  final String getHistoricalPeriodsQuery = """
    query GetHistorialPeriodos(\$registro: String!) {
      historialPeriodosEstudiante(registro: \$registro) {
        codigo
        nombre
      }
    }
  """;

  final String getEnrollmentQuery = """
    query GetEnrollment(\$registro: String!, \$codigoCarrera: String, \$codigoPeriodo: String) {
      inscripcionCompleta(registro: \$registro, codigoCarrera: \$codigoCarrera, codigoPeriodo: \$codigoPeriodo) {
        id
        estudiante {
          registro
          nombreCompleto
        }
        periodoAcademico {
          codigo
          nombre
        }
        fechaInscripcionAsignada
        fechaInscripcionRealizada
        estado
        boletaGenerada
        numeroBoleta
        materiasInscritas {
          materia {
            codigo
            nombre
            creditos
          }
          oferta {
            grupo
            semestre
            horario
          }
          grupo
        }
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;
    final codigoCarrera = provider.selectedCareer?.code;
    final bool isTabletOrDesktop = Responsive.isTabletOrDesktop(context);

    return MainLayout(
      title: 'Boleta de Inscripción',
      subtitle: 'Comprobante oficial de materias inscritas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPeriodSelector(studentRegister ?? ''),
          Expanded(
            child: Query(
              options: QueryOptions(
                document: gql(getEnrollmentQuery),
                variables: {
                  'registro': studentRegister ?? '',
                  'codigoCarrera': codigoCarrera,
                  'codigoPeriodo': selectedPeriodCodigo,
                },
                fetchPolicy: FetchPolicy.networkOnly,
              ),
              builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
                if (result.hasException) return _buildError(context, result.exception.toString(), refetch);
                if (result.isLoading) return const Center(child: CircularProgressIndicator());
                final data = result.data?['inscripcionCompleta'];
                // Si no hay inscripción real, mostrar demo con datos de muestra
                if (data == null) return _buildDemoBoletaOrEmpty(context, provider, isTabletOrDesktop);
                
                return isTabletOrDesktop 
                    ? _buildWebBoleta(context, data, provider)
                    : _buildMobileBoleta(context, data, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(String registro) {
    return Query(
      options: QueryOptions(
        document: gql(getHistoricalPeriodsQuery),
        variables: {'registro': registro},
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        final periods = (result.data?['historialPeriodosEstudiante'] as List<dynamic>?) ?? [];

        if (periods.isEmpty && !result.isLoading) {
          // Si no hay historial disponible, no mostrar el selector
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: UAGRMTheme.primaryBlue.withValues(alpha: 0.06),
          child: Row(
            children: [
              const Icon(Icons.history, size: 18, color: UAGRMTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text('Periodo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              if (result.isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                DropdownButton<String?>(
                  value: selectedPeriodCodigo,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  hint: const Text('Actual', style: TextStyle(fontSize: 13)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Actual', style: TextStyle(fontSize: 13)),
                    ),
                    ...periods.map((p) {
                      final codigo = p['codigo']?.toString() ?? '';
                      final nombre = p['nombre']?.toString() ?? codigo;
                      return DropdownMenuItem<String?>(
                        value: codigo,
                        child: Text(nombre, style: const TextStyle(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => selectedPeriodCodigo = val),
                ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildWebBoleta(BuildContext context, Map<String, dynamic> data, RegistrationProvider provider) {
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];
    final carreraNombre = provider.selectedCareer?.name ?? '';
    final carreraCodigo = provider.selectedCareer?.code ?? '';
    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2025 - Semestre Regular';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con botón de Imprimir + toggle de orientación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Boleta de Inscripción',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: UAGRMTheme.primaryBlue)),
                  Row(
                    children: [
                      // Toggle Portrait / Landscape
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
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentTabIndex == 1) {
                            PdfGenerator.generateAndPrintBoletaGrafica(
                              data: data,
                              carreraNombre: carreraNombre,
                              carreraCodigo: carreraCodigo,
                              landscape: _landscape,
                            );
                          } else {
                            PdfGenerator.generateAndPrintBoleta(
                              data: data,
                              carreraNombre: carreraNombre,
                              carreraCodigo: carreraCodigo,
                              landscape: _landscape,
                            );
                          }
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
                ],
              ),
              const SizedBox(height: 24),
              // Pestañas simuladas
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTabIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _currentTabIndex == 0 
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Text('Boleta Normal', style: TextStyle(fontWeight: FontWeight.bold, color: _currentTabIndex == 0 ? UAGRMTheme.primaryBlue : UAGRMTheme.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _currentTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTabIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _currentTabIndex == 1 
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Text('Boleta Gráfica', style: TextStyle(fontWeight: FontWeight.bold, color: _currentTabIndex == 1 ? UAGRMTheme.primaryBlue : UAGRMTheme.textGrey)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contenedor principal de la Boleta
              StandardTableContainer(
                child: Column(
                    children: [
                    // Contenido Condicional: Normal vs Gráfica
                    _currentTabIndex == 0 
                      ? Column(
                          children: [
                            // Título Universitario Normal
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Text('Universidad Autónoma Gabriel René Moreno', style: TextStyle(fontSize: 14, color: UAGRMTheme.textGrey)),
                                  const SizedBox(height: 8),
                                  const Text('BOLETA DE INSCRIPCIÓN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark, letterSpacing: 1.2)),
                                  const SizedBox(height: 8),
                                  Text('Período: ' + nombrePeriodo, style: const TextStyle(fontSize: 14, color: UAGRMTheme.textGrey)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Información Estudiante
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _infoRow('Estudiante: ', estudiante['nombreCompleto'] ?? ''),
                                      const SizedBox(height: 8),
                                      _infoRow('Carrera: ', carreraNombre),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _infoRow('Registro: ', estudiante['registro']?.toString() ?? ''),
                                      const SizedBox(height: 8),
                                      _infoRow('CI: ', '9876543'), // Fallback mock exacto
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _buildCleanTable(materias),
                            // Resumen Footer
                            Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.centerLeft,
                              child: Text('Total de materias inscritas: ' + materias.length.toString(), style: const TextStyle(color: UAGRMTheme.textGrey, fontSize: 13)),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Text('Universidad Autónoma Gabriel René Moreno', style: TextStyle(fontSize: 14, color: UAGRMTheme.textGrey)),
                                  const SizedBox(height: 8),
                                  const Text('BOLETA GRÁFICA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark, letterSpacing: 1.2)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: ScheduleGridView(materias: materias, isLarge: true),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: UAGRMTheme.textDark),
        children: [
          TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildCleanTable(List<dynamic> materias) {
    if (materias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text('No hay materias inscritas', style: TextStyle(color: UAGRMTheme.textGrey)),
      );
    }
    return AppTableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          AppTableHeader(
            children: const [
              SizedBox(width: 40, child: AppHeaderCell('Nro')),
              SizedBox(width: 80, child: AppHeaderCell('Sigla')),
              Expanded(flex: 3, child: AppHeaderCell('Materia')),
              SizedBox(width: 50, child: AppHeaderCell('Grupo')),
              Expanded(flex: 2, child: AppHeaderCell('Docente')),
              Expanded(flex: 2, child: AppHeaderCell('Horario')),
              SizedBox(width: 80, child: AppHeaderCell('Turno')),
              SizedBox(width: 80, child: AppHeaderCell('Aula')),
              SizedBox(width: 80, child: AppHeaderCell('Estado', textAlign: TextAlign.center)),
            ],
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: materias.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = materias[index];
              final i = index + 1;
              final materia = item['materia'] as Map<String, dynamic>? ?? {};
              final oferta = item['oferta'] as Map<String, dynamic>? ?? {};
              final nroStr = i.toString();
              final aulaStr = 'Aula ' + (100 + i).toString();
               
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text(nroStr, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark))),
                    SizedBox(width: 80, child: Text(materia['codigo'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: UAGRMTheme.textDark))),
                    Expanded(flex: 3, child: Text(materia['nombre'] ?? '', style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark))),
                    SizedBox(width: 50, child: Text(item['grupo'] ?? oferta['grupo'] ?? '', style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark))),
                    Expanded(flex: 2, child: Text(oferta['docente'] ?? 'Dr. Por Asignar', style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark))),
                    Expanded(flex: 2, child: Text(TimeFormatter.formatHorario(oferta['horario'] ?? ''), style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey))),
                    SizedBox(width: 80, child: _buildNiceTurno(oferta['horario'] ?? '')),
                    SizedBox(width: 80, child: Text(aulaStr, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey))),
                    const SizedBox(width: 80, child: AppEstadoBadge('Inscrito')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNiceTurno(String horario) {
    return AppTurnoBadge(horario);
  }

  /// Boleta de demostración cuando no hay inscripción confirmada.
  Widget _buildDemoBoletaOrEmpty(BuildContext context, RegistrationProvider provider, bool isTabletOrDesktop) {
    final demoData = <String, dynamic>{
      'estudiante': {
        'nombreCompleto': 'Estudiante UAGRM',
        'registro': provider.studentRegister ?? '000000',
      },
      'periodoAcademico': {'nombre': '1/2026 Semestre Regular', 'codigo': '1/2026'},
      'materiasInscritas': [
        {'materia': {'codigo': 'MAT-101', 'nombre': 'Matemática I',    'creditos': 6}, 'oferta': {'grupo': 'A', 'semestre': 1, 'horario': 'L-M-V 07:00-09:00', 'docente': 'Ing. Carlos López'}, 'grupo': 'A'},
        {'materia': {'codigo': 'FIS-101', 'nombre': 'Física I',         'creditos': 5}, 'oferta': {'grupo': 'B', 'semestre': 1, 'horario': 'M-J 14:00-16:00',   'docente': 'Lic. Ana Flores'},   'grupo': 'B'},
        {'materia': {'codigo': 'INF-210', 'nombre': 'Programación I',   'creditos': 4}, 'oferta': {'grupo': 'A', 'semestre': 2, 'horario': 'L-M-V 09:00-11:00', 'docente': 'Ing. Luis Pérez'},   'grupo': 'A'},
        {'materia': {'codigo': 'EST-101', 'nombre': 'Estadística',      'creditos': 5}, 'oferta': {'grupo': 'C', 'semestre': 2, 'horario': 'M-J 18:00-20:00',   'docente': 'Mg. Rosa Vargas'},   'grupo': 'C'},
      ],
    };
    if (isTabletOrDesktop) {
      return _buildWebBoleta(context, demoData, provider);
    } else {
      return _buildMobileBoleta(context, demoData, provider);
    }
  }

  Widget _buildMobileBoleta(BuildContext context, Map<String, dynamic> data, RegistrationProvider provider) {
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];
    final carreraNombre = provider.selectedCareer?.name ?? '';
    final carreraCodigo = provider.selectedCareer?.code ?? '';
    const modalidad = 'PRESENCIAL';
    const lugar = 'SANTA CRUZ';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(periodo),
          const SizedBox(height: 12),
          _buildStudentInfo(estudiante, {'nombre': carreraNombre, 'codigo': carreraCodigo}, lugar),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: _buildCleanTable(materias),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummary(materias),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Boleta PDF', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UAGRMTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => PdfGenerator.generateAndPrintBoleta(
                    data: data,
                    carreraNombre: carreraNombre,
                    carreraCodigo: carreraCodigo,
                    landscape: _landscape,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.grid_on, size: 16),
                  label: const Text('Gráfica PDF', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UAGRMTheme.sidebarPanel,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => PdfGenerator.generateAndPrintBoletaGrafica(
                    data: data,
                    carreraNombre: carreraNombre,
                    carreraCodigo: carreraCodigo,
                    landscape: _landscape,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> periodo) {
    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2026';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: UAGRMTheme.primaryBlue, 
        borderRadius: BorderRadius.circular(6)
      ),
      child: Text(
        'BOLETA DE INSCRIPCIÓN $nombrePeriodo', 
        textAlign: TextAlign.center, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildStudentInfo(Map<String, dynamic> estudiante, Map<String, dynamic> carrera, String lugar) {
    final registro = estudiante['registro']?.toString() ?? '';
    final nombre = estudiante['nombreCompleto'] ?? '';
    final carreraNombre = '${carrera['codigo'] ?? ''} ${carrera['nombre'] ?? ''}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 12), children: [const TextSpan(text: 'Registro No. ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: registro), const TextSpan(text: '  Nombre:', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: nombre)])),
          const SizedBox(height: 4),
          RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 12), children: [const TextSpan(text: 'Carrera: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: carreraNombre.trim())])),
          const SizedBox(height: 4),
          RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 12), children: [const TextSpan(text: 'Lugar: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: lugar.toUpperCase())])),
        ],
      ),
    );
  }



  Widget _buildSummary(List<dynamic> materias) {
    final totalCreditos = materias.fold<int>(0, (sum, item) => sum + ((item['materia']?['creditos'] as int?) ?? 0));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8), border: Border.all(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(label: 'Materias', value: '${materias.length}'),
          _SummaryChip(label: 'Créditos Totales', value: '$totalCreditos'),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, VoidCallback? refetch) {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48), const SizedBox(height: 16), Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)), const SizedBox(height: 16), ElevatedButton(onPressed: refetch, child: const Text('Reintentar'))])));
  }

  Widget _buildEmpty() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No hay inscripción registrada', style: TextStyle(fontSize: 16, color: Colors.grey)), SizedBox(height: 8), Text('Confirma tu inscripción para ver la boleta.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center)]));
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: UAGRMTheme.primaryBlue)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
  }
}
