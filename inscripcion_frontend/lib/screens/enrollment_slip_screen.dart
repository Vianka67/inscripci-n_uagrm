import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/utils/time_formatter.dart';

class EnrollmentSlipScreen extends StatelessWidget {
  const EnrollmentSlipScreen({super.key});

  final String getEnrollmentQuery = """
    query GetEnrollment(\$registro: String!, \$codigoCarrera: String) {
      inscripcionCompleta(registro: \$registro, codigoCarrera: \$codigoCarrera) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boleta de Inscripción'),
        centerTitle: true,
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getEnrollmentQuery),
          variables: {
            'registro': studentRegister ?? '',
            'codigoCarrera': codigoCarrera,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return _buildError(context, result.exception.toString(), refetch);
          }
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = result.data?['inscripcionCompleta'];
          if (data == null) {
            return _buildEmpty();
          }

          final prov = context.read<RegistrationProvider>();
          return _buildBoleta(context, data, prov);
        },
      ),
    );
  }

  Widget _buildBoleta(BuildContext context, Map<String, dynamic> data, RegistrationProvider provider) {
    final estudiante = data['estudiante'] as Map<String, dynamic>? ?? {};
    final periodo = data['periodoAcademico'] as Map<String, dynamic>? ?? {};
    final materias = data['materiasInscritas'] as List<dynamic>? ?? [];
    // Datos de la carrera del provider local (no en la query)
    final carreraNombre = provider.selectedCareer?.name ?? '';
    final carreraCodigo = provider.selectedCareer?.code ?? '';
    const modalidad = 'PRESENCIAL';
    const lugar = 'SANTA CRUZ';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Encabezado estilo UAGRM ──
          _buildHeader(periodo),
          const SizedBox(height: 12),

          // ── Datos del estudiante ──
          _buildStudentInfo(estudiante, {'nombre': carreraNombre, 'codigo': carreraCodigo}, lugar),
          const SizedBox(height: 16),

          // ── Tabla académica ──
          _buildAcademicTable(materias, modalidad),
          const SizedBox(height: 16),

          // ── Resumen ──
          _buildSummary(materias),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> periodo) {
    final nombrePeriodo = periodo['nombre'] ?? periodo['codigo'] ?? '1/2026';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            'BOLETA DE INSCRIPCION $nombrePeriodo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(
    Map<String, dynamic> estudiante,
    Map<String, dynamic> carrera,
    String lugar,
  ) {
    final registro = estudiante['registro']?.toString() ?? '';
    final nombre = estudiante['nombreCompleto'] ?? '';
    final carreraNombre = '${carrera['codigo'] ?? ''} ${carrera['nombre'] ?? ''}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 12),
              children: [
                const TextSpan(text: 'Registro No. ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: registro),
                const TextSpan(text: '  Nombre:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: nombre),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 12),
              children: [
                const TextSpan(text: 'Carrera: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: carreraNombre.trim()),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 12),
              children: [
                const TextSpan(text: 'Lugar: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: lugar.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicTable(List<dynamic> materias, String modalidad) {
    const headerColor = Color(0xFFEEEEEE);
    const evenRowColor = Color(0xFFF5F5F5);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 800, // Anchura total deseada para permitir el scroll cómodo
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(70),  // SIGLA
              1: FixedColumnWidth(55),  // GRUPO
              2: FlexColumnWidth(4),    // NOMBRE MATERIA (se expandirá en el Fixed total)
              3: FixedColumnWidth(45),  // CRÉD
              4: FixedColumnWidth(45),  // SEM
              5: FixedColumnWidth(150), // HORARIO (más espacio para evitar cortes)
              6: FixedColumnWidth(45),  // REPR
              7: FixedColumnWidth(100), // MODALIDAD
            },
            children: [
              // ── Encabezado de tabla ──
              TableRow(
                decoration: const BoxDecoration(color: headerColor),
                children: [
                  'SIGLA', 'GRUPO', 'NOMBRE MATERIA', 'CRÉD', 'SEM', 'HORARIO', 'REPR', 'MODALIDAD'
                ].map((text) => _buildTableCell(text, isHeader: true)).toList(),
              ),

              // ── Filas de materias ──
              if (materias.isEmpty)
                TableRow(
                  children: [
                    const TableCell(child: SizedBox.shrink()),
                    const TableCell(child: SizedBox.shrink()),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No hay materias inscritas',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const TableCell(child: SizedBox.shrink()),
                    const TableCell(child: SizedBox.shrink()),
                    const TableCell(child: SizedBox.shrink()),
                    const TableCell(child: SizedBox.shrink()),
                    const TableCell(child: SizedBox.shrink()),
                  ],
                )
              else
                ...materias.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final materia = item['materia'] as Map<String, dynamic>? ?? {};
                  final oferta = item['oferta'] as Map<String, dynamic>? ?? {};
                  
                  final grupo = oferta['grupo'] ?? item['grupo'] ?? '';
                  final sem = '${oferta['semestre'] ?? 0}';
                  final horario = TimeFormatter.formatHorario(oferta['horario'] ?? '');
                  final codigo = materia['codigo'] ?? '';
                  final nombre = materia['nombre'] ?? '';
                  final creditos = '${materia['creditos'] ?? ''}';
                  const repr = '0';
                  final modalidadRow = modalidad;

                  return TableRow(
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? evenRowColor : Colors.white,
                    ),
                    children: [
                      codigo, grupo, nombre, creditos, sem, horario, repr, modalidadRow
                    ].map((text) => _buildTableCell(text, isHeader: false)).toList(),
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
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHeader ? 8 : 9,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSummary(List<dynamic> materias) {
    final totalCreditos = materias.fold<int>(
      0,
      (sum, item) => sum + ((item['materia']?['creditos'] as int?) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UAGRMTheme.primaryBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UAGRMTheme.primaryBlue.withOpacity(0.3)),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay inscripción registrada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Confirma tu inscripción para ver la boleta.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: UAGRMTheme.primaryBlue,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
