import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/subject.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';

class EnabledSubjectsScreen extends StatelessWidget {
  const EnabledSubjectsScreen({super.key});

  final String getSubjectsQuery = """
    query GetEnabledSubjects(\$registro: Int!, \$carr: Int!, \$plan: String!, \$lugar: Int!, \$sem: String!, \$ano: Int!, \$nroSerie: Int!, \$proceso: String!) {
      materiaOferta(registro: \$registro, carr: \$carr, plan: \$plan, lugar: \$lugar, sem: \$sem, ano: \$ano, nroSerie: \$nroSerie, proceso: \$proceso) {
        materiaCodigo
        materiaNombre
        semestre
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;

    return MainLayout(
      title: 'Materias Habilitadas',
      subtitle: 'Visualiza las materias disponibles para tu inscripción este periodo',
      child: _buildQuery(context, provider, studentRegister, isWeb: Responsive.isTabletOrDesktop(context)),
    );
  }

  Widget _buildQuery(BuildContext context, RegistrationProvider provider, String? studentRegister, {required bool isWeb}) {
    return Query(
      options: QueryOptions(
        document: gql(getSubjectsQuery),
        variables: {
          'registro': int.tryParse(studentRegister ?? '0') ?? 0,
          'carr': int.tryParse(provider.selectedCareer?.code ?? '0') ?? 0,
          'plan': '1',
          'lugar': 4271,
          'sem': '1',
          'ano': 2026,
          'nroSerie': 999123,
          'proceso': 'I'
        },
        fetchPolicy: FetchPolicy.networkOnly, // Add fetchPolicy to ensure fresh data
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: UAGRMTheme.primaryBlue),
                SizedBox(height: 16),
                Text('Cargando materias habilitadas...', style: TextStyle(color: UAGRMTheme.textGrey)),
              ],
            ),
          );
        }

        if (result.hasException) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text('Error de carga:\n${result.exception.toString()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
                ],
              ),
            ),
          );
        }

        final List<Subject> subjects;
        try {
          final subjectsData = result.data?['materiaOferta'] as List<dynamic>? ?? [];
          subjects = subjectsData.map((data) => Subject(
            code: data['materiaCodigo']?.toString() ?? '',
            name: data['materiaNombre']?.toString() ?? 'Sin nombre',
            credits: 0,
            semester: int.tryParse(data['semestre']?.toString() ?? '0') ?? 0,
            isRequired: true,
            isEnabled: true,
          )).toList();
        } catch (e) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
                  const SizedBox(height: 16),
                  const Text('Error al procesar datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Detalle técnico: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: refetch, child: const Text('Reintentar sincronización')),
                ],
              ),
            ),
          );
        }

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No hay materias habilitadas',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: UAGRMTheme.primaryBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se encontraron asignaturas para el registro ${studentRegister ?? "N/A"}\nen la carrera ${provider.selectedCareer?.name ?? "No seleccionada"}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: refetch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Consultar nuevamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UAGRMTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          );
        }

        final isMobile = Responsive.isMobile(context);
        final flexValues = isMobile ? [2, 5, 2] : [1, 4, 1, 1, 1];

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta superior con resumen
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.list_alt_outlined, color: UAGRMTheme.sidebarBg, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Resumen de Materias Habilitadas',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: UAGRMTheme.sidebarBg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _summaryBadge('${subjects.length}', 'habilitadas', UAGRMTheme.primaryBlue)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryBadge(
                                '${subjects.where((s) => s.isRequired).length}',
                                'obligatorias',
                                UAGRMTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tabla de materias
                  StandardTableContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StandardFlexHeader(
                          labels: isMobile ? ['CÓDIGO', 'ASIGNATURA', 'NIVEL'] : ['CÓDIGO', 'ASIGNATURA', 'CRÉDS', 'NIVEL', 'TIPO'],
                          flexValues: flexValues,
                        ),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final s = subjects[index];
                            return StandardFlexRow(
                              flexValues: flexValues,
                              isLast: index == subjects.length - 1,
                              cells: [
                                tableText(s.code, isMobile, bold: true),
                                tableText(s.name, isMobile, bold: true),
                                if (!isMobile)
                                  tableText('${s.credits}', isMobile),
                                tableText('${s.semester}', isMobile),
                                if (!isMobile)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: AppEstadoBadge(
                                      s.isRequired ? 'OBLIG.' : 'ELEC.',
                                      color: s.isRequired ? UAGRMTheme.errorRed : UAGRMTheme.successGreen,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryBadge(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(count, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 22, color: color)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w400, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
