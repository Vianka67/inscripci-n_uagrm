import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';

class BlockedStatusScreen extends StatefulWidget {
  const BlockedStatusScreen({super.key});

  @override
  State<BlockedStatusScreen> createState() => _BlockedStatusScreenState();
}

class _BlockedStatusScreenState extends State<BlockedStatusScreen> {
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

  final String getBlockStatusQuery = """
    query GetBlockStatus(\$registro: Int!) {
      bloqueo(registro: \$registro) {
        cobBloq
        desBloq
        porroga
        desbTemp
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final int registro = int.tryParse(provider.studentRegister ?? '0') ?? 0;

    return MainLayout(
      title: 'Estado de Bloqueos',
      subtitle: 'Verifica si tienes impedimentos para tu inscripción',
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Query(
                  options: QueryOptions(
                    document: gql(getBlockStatusQuery),
                    variables: {'registro': registro},
                    fetchPolicy: FetchPolicy.networkOnly,
                  ),
                  builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
                    if (result.isLoading) {
                      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                    }
                    if (result.hasException) {
                      return _buildError(result.exception.toString(), refetch);
                    }

                    final bloqueos = result.data?['bloqueo'] as List<dynamic>? ?? [];
                    final isBloqueado = bloqueos.isNotEmpty;

                    return Column(
                      children: [
                        _buildStatusHeader(isBloqueado),
                        const SizedBox(height: 32),
                        if (isBloqueado) ...[
                          _buildBlocksTable(bloqueos),
                          const SizedBox(height: 24),
                          _buildWarningFooter(),
                        ] else
                          _buildSuccessFooter(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isBloqueado) {
    final isLarge = Responsive.isDesktop(context);
    if (isBloqueado) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLarge ? 32 : 24),
        decoration: BoxDecoration(
          color: UAGRMTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UAGRMTheme.errorRed.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.lock_person_rounded, color: UAGRMTheme.errorRed, size: 56),
            SizedBox(height: 16),
            Text(
              'CUENTA BLOQUEADA',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: UAGRMTheme.errorRed, letterSpacing: 0.5),
            ),
            SizedBox(height: 8),
            Text(
              'Tu registro presenta impedimentos que debes regularizar para inscribirte.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: UAGRMTheme.errorRed),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 32 : 24),
      decoration: BoxDecoration(
        color: UAGRMTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UAGRMTheme.successGreen.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: UAGRMTheme.successGreen, size: 56),
          SizedBox(height: 16),
          Text(
            'SIN BLOQUEOS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: UAGRMTheme.successGreen, letterSpacing: 0.5),
          ),
          SizedBox(height: 8),
          Text(
            '¡Excelente! No tienes trámites pendientes que impidan tu inscripción.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: UAGRMTheme.successGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksTable(List<dynamic> bloqueos) {
    final isMobile = Responsive.isMobile(context);
    final labels = isMobile 
        ? const ['CÓD.', 'MOTIVO'] 
        : const ['CÓDIGO', 'DESCRIPCIÓN DEL BLOQUEO', 'OBSERVACIÓN / PRÓRROGA'];
    
    final flexValues = isMobile ? [2, 8] : [2, 6, 4];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'DETALLE DE TRÁMITES PENDIENTES',
            style: GoogleFonts.outfit(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: UAGRMTheme.textGrey, 
              letterSpacing: 0.5
            ),
          ),
        ),
        StandardTableContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StandardFlexHeader(labels: labels, flexValues: flexValues),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bloqueos.length,
                itemBuilder: (context, index) {
                  final b = bloqueos[index] as Map<String, dynamic>;
                  final cod = b['cobBloq']?.toString() ?? '-';
                  final desc = b['desBloq']?.toString() ?? '-';
                  final obs = b['porroga']?.toString() ?? '-';

                  return StandardFlexRow(
                    flexValues: flexValues,
                    isLast: index == bloqueos.length - 1,
                    cells: [
                      tableText(cod, isMobile, bold: true),
                      tableText(desc, isMobile, textAlign: TextAlign.left),
                      if (!isMobile)
                        tableText(obs, isMobile, color: UAGRMTheme.textGrey),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UAGRMTheme.errorRed.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: UAGRMTheme.errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Para levantar estos bloqueos, por favor dirígete a las oficinas correspondientes (Caja, CPD o tu Facultad).',
              style: GoogleFonts.inter(fontSize: 12, color: UAGRMTheme.errorRed, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UAGRMTheme.successGreen.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: UAGRMTheme.successGreen, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu registro está habilitado para todos los procesos de este periodo académico.',
              style: TextStyle(fontSize: 13, color: UAGRMTheme.successGreen, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, VoidCallback? refetch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text('Error al conectar con Informix: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
