import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';

class AnulacionesScreen extends StatelessWidget {
  const AnulacionesScreen({super.key});

  final String getTramitesQuery = """
    query GetTramitesAnulacion(\$reg: Int!) {
      obtenerTramitesAnulacion(reg: \$reg) {
        reg sem ano carr plan lugar modalidad codMotiv codProc aB
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final registro = int.tryParse(provider.studentRegister ?? '0') ?? 0;
    final isMobile = Responsive.isMobile(context);

    return MainLayout(
      title: 'Anulaciones',
      subtitle: 'Trámites de anulación de inscripción',
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner informativo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [UAGRMTheme.errorRed.withValues(alpha: 0.08), Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: UAGRMTheme.errorRed.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: UAGRMTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cancel_outlined, color: UAGRMTheme.errorRed, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trámites de Anulación',
                                style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: UAGRMTheme.errorRed)),
                            const SizedBox(height: 4),
                            Text(
                              'Consulta aquí el historial de tus solicitudes de anulación de boletas e inscripciones.',
                              style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tabla de trámites
                Query(
                  options: QueryOptions(
                    document: gql(getTramitesQuery),
                    variables: {'reg': registro},
                    fetchPolicy: FetchPolicy.networkOnly,
                  ),
                  builder: (QueryResult result,
                      {VoidCallback? refetch, FetchMore? fetchMore}) {
                    if (result.isLoading) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator()));
                    }

                    if (result.hasException) {
                      return _buildError(result.exception.toString(), refetch);
                    }

                    final tramites =
                        result.data?['obtenerTramitesAnulacion'] as List<dynamic>? ?? [];

                    if (tramites.isEmpty) {
                      return _buildEmpty();
                    }

                    return _buildTable(tramites, isMobile);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<dynamic> tramites, bool isMobile) {
    final labels = isMobile
        ? const ['PERÍODO', 'CARRERA', 'PROC.', 'ESTADO']
        : const ['PERÍODO', 'AÑO', 'CARRERA', 'PLAN', 'LUGAR', 'MOD.', 'PROC.', 'ESTADO'];
    final flexValues = isMobile ? [3, 4, 3, 3] : [2, 2, 3, 2, 2, 2, 2, 2];

    return StandardTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardFlexHeader(labels: labels, flexValues: flexValues),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tramites.length,
            itemBuilder: (context, index) {
              final t = tramites[index] as Map<String, dynamic>;
              final estado = t['aB']?.toString() == 'A' ? 'Activo' : 'Anulado';
              return StandardFlexRow(
                flexValues: flexValues,
                isLast: index == tramites.length - 1,
                cells: [
                  tableText(t['sem']?.toString() ?? '-', isMobile, bold: true),
                  if (!isMobile) tableText(t['ano']?.toString() ?? '-', isMobile),
                  tableText(t['carr']?.toString() ?? '-', isMobile),
                  if (!isMobile) tableText(t['plan']?.toString() ?? '-', isMobile),
                  if (!isMobile) tableText(t['lugar']?.toString() ?? '-', isMobile),
                  if (!isMobile) tableText(t['modalidad']?.toString() ?? '-', isMobile),
                  AppProcessBadge(t['codProc']?.toString() ?? '-'),
                  Center(
                    child: AppEstadoBadge(
                      estado,
                      color: estado == 'Activo'
                          ? UAGRMTheme.successGreen
                          : UAGRMTheme.errorRed,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, VoidCallback? refetch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
            const SizedBox(height: 12),
            Text('Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: UAGRMTheme.successGreen),
          const SizedBox(height: 16),
          Text('Sin trámites de anulación',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w600, color: UAGRMTheme.textDark)),
          const SizedBox(height: 8),
          const Text(
            'No tienes ningún trámite de anulación registrado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UAGRMTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
