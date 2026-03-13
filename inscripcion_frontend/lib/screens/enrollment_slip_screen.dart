import 'package:inscripcion_frontend/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/utils/time_formatter.dart';
import 'package:inscripcion_frontend/utils/pdf_generator.dart';
import 'package:inscripcion_frontend/widgets/web_page_header.dart';

class EnrollmentSlipScreen extends StatefulWidget {
  const EnrollmentSlipScreen({super.key});

  @override
  State<EnrollmentSlipScreen> createState() => _EnrollmentSlipScreenState();
}

class _EnrollmentSlipScreenState extends State<EnrollmentSlipScreen> {
  // Periodo seleccionado (null = periodo actual/más reciente)
  String? selectedPeriodCodigo;

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
    if (isTabletOrDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebPageHeader(
                title: 'Boleta de Inscripción',
                icon: Icons.description_outlined,
                subtitle: 'Comprobante oficial de materias inscritas',
              ),
              // Selector de periodo histórico
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
                    if (data == null) return _buildEmpty();
                    return _buildWebBoleta(context, data, provider);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Móvil: layout original
    return Scaffold(
      appBar: AppBar(title: const Text('Boleta de Inscripción'), centerTitle: true),
      body: Column(
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
                if (data == null) return _buildEmpty();
                return _buildMobileBoleta(context, data, provider);
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

  // ─── BOLETA WEB ───────────────────────────────────────────────────────────────

  Widget _buildWebBoleta(BuildContext context, Map<String, dynamic> data, RegistrationProvider provider) {
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];
    final carreraNombre = provider.selectedCareer?.name ?? '';
    final carreraCodigo = provider.selectedCareer?.code ?? '';
    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2026';
    final totalCreditos = materias.fold<int>(0, (sum, item) => sum + ((item['materia']?['creditos'] as int?) ?? 0));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta boleta estilo documento
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado boleta
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: UAGRMTheme.primaryBlue,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'BOLETA DE INSCRIPCIÓN — $nombrePeriodo',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, letterSpacing: 0.3),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('INSCRITO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UAGRMTheme.successGreen)),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.white, size: 20),
                            tooltip: 'Descargar / Imprimir PDF',
                            onPressed: () => PdfGenerator.generateAndPrintBoleta(
                              data: data,
                              carreraNombre: carreraNombre,
                              carreraCodigo: carreraCodigo,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Datos del estudiante
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          _webInfoField('Registro', estudiante['registro']?.toString() ?? ''),
                          const SizedBox(width: 32),
                          _webInfoField('Nombre', estudiante['nombreCompleto'] ?? ''),
                          const SizedBox(width: 32),
                          _webInfoField('Carrera', '$carreraCodigo $carreraNombre'),
                          const SizedBox(width: 32),
                          _webInfoField('Lugar', 'SANTA CRUZ'),
                        ],
                      ),
                    ),

                    // Divider
                    Divider(height: 1, color: Colors.grey.shade200),

                    // Tabla de materias
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildWebTable(materias),
                    ),

                    // Resumen
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: UAGRMTheme.primaryBlue.withValues(alpha: 0.04),
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                      ),
                      child: Row(
                        children: [
                          _webSummaryItem('${materias.length}', 'Materias inscritas'),
                          const SizedBox(width: 32),
                          _webSummaryItem('$totalCreditos', 'Créditos totales'),
                          const Spacer(),
                          Text(
                            'MODALIDAD: PRESENCIAL',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5),
                          ),
                        ],
                      ),
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

  Widget _webInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: UAGRMTheme.textGrey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: UAGRMTheme.textDark)),
      ],
    );
  }

  Widget _webSummaryItem(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: UAGRMTheme.primaryBlue)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey)),
      ],
    );
  }

  Widget _buildWebTable(List<dynamic> materias) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: const BoxDecoration(
              color: UAGRMTheme.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 80, child: Text('SIGLA', style: headerStyle)),
                SizedBox(width: 55, child: Text('GRUPO', style: headerStyle, textAlign: TextAlign.center)),
                Expanded(child: Text('NOMBRE MATERIA', style: headerStyle)),
                SizedBox(width: 55, child: Text('CRÉD', style: headerStyle, textAlign: TextAlign.center)),
                SizedBox(width: 45, child: Text('SEM', style: headerStyle, textAlign: TextAlign.center)),
                SizedBox(width: 180, child: Text('HORARIO', style: headerStyle)),
                SizedBox(width: 100, child: Text('MODALIDAD', style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...materias.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final materia = item['materia'] as Map<String, dynamic>? ?? {};
            final oferta = item['oferta'] as Map<String, dynamic>? ?? {};
            return Container(
              decoration: BoxDecoration(
                color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(materia['codigo'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: UAGRMTheme.primaryBlue))),
                  SizedBox(width: 55, child: Text(oferta['grupo'] ?? item['grupo'] ?? '', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text(materia['nombre'] ?? '', style: const TextStyle(fontSize: 12))),
                  SizedBox(width: 55, child: Text('${materia['creditos'] ?? ''}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 45, child: Text('${oferta['semestre'] ?? 0}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 180, child: Text(TimeFormatter.formatHorario(oferta['horario'] ?? ''), style: const TextStyle(fontSize: 11))),
                  SizedBox(width: 100, child: Text('PRESENCIAL', style: const TextStyle(fontSize: 11, color: UAGRMTheme.textGrey), textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── BOLETA MÓVIL (original) ──────────────────────────────────────────────────

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
          _buildAcademicTable(materias, modalidad),
          const SizedBox(height: 16),
          _buildSummary(materias),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Descargar / Imprimir PDF'),
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
            ),
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

  Widget _buildAcademicTable(List<dynamic> materias, String modalidad) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 800,
          child: Table(
            columnWidths: const {0: FixedColumnWidth(70), 1: FixedColumnWidth(55), 2: FlexColumnWidth(4), 3: FixedColumnWidth(45), 4: FixedColumnWidth(45), 5: FixedColumnWidth(150), 6: FixedColumnWidth(45), 7: FixedColumnWidth(100)},
            children: [
              TableRow(
                decoration: const BoxDecoration(color: UAGRMTheme.primaryBlue),
                children: ['SIGLA', 'GRUPO', 'NOMBRE MATERIA', 'CRÉD', 'SEM', 'HORARIO', 'REPR', 'MODALIDAD'].map((t) => _buildTableCell(t, isHeader: true)).toList(),
              ),
              if (materias.isEmpty)
                TableRow(children: [const TableCell(child: SizedBox.shrink()), const TableCell(child: SizedBox.shrink()), TableCell(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No hay materias inscritas', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))))), const TableCell(child: SizedBox.shrink()), const TableCell(child: SizedBox.shrink()), const TableCell(child: SizedBox.shrink()), const TableCell(child: SizedBox.shrink()), const TableCell(child: SizedBox.shrink())])
              else
                ...materias.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final materia = item['materia'] as Map<String, dynamic>? ?? {};
                  final oferta = item['oferta'] as Map<String, dynamic>? ?? {};
                  return TableRow(
                    decoration: BoxDecoration(color: i % 2 == 0 ? const Color(0xFFF5F5F5) : Colors.white),
                    children: [materia['codigo'] ?? '', oferta['grupo'] ?? item['grupo'] ?? '', materia['nombre'] ?? '', '${materia['creditos'] ?? ''}', '${oferta['semestre'] ?? 0}', TimeFormatter.formatHorario(oferta['horario'] ?? ''), '0', modalidad].map((t) => _buildTableCell(t, isHeader: false)).toList(),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {required bool isHeader}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5), bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))),
        child: Text(text, style: TextStyle(fontSize: isHeader ? 8 : 9, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: isHeader ? Colors.white : Colors.black87), textAlign: TextAlign.center),
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
