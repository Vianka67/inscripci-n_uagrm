import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

class EnrollmentDatesScreen extends StatefulWidget {
  const EnrollmentDatesScreen({super.key});

  @override
  State<EnrollmentDatesScreen> createState() => _EnrollmentDatesScreenState();
}

class _EnrollmentDatesScreenState extends State<EnrollmentDatesScreen> {
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

  final String getDatesQuery = """
    query GetEnrollmentDates(\$carr: Int!, \$plan: String!, \$sem: String!, \$ano: Int!, \$nroSerie: Int!) {
      calendario(carr: \$carr, plan: \$plan, sem: \$sem, ano: \$ano) {
        fecIniIns fecFinIns
        fecIniRez fecFinRez
        fecIniAdi fecFinAdi
        fecIniRet fecFinRet
      }
      matIns(nroSerie: \$nroSerie) {
        diaIns horaIns
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();

    return MainLayout(
      title: 'Fecha/Hora Inscripción',
      subtitle: 'Consulta tus fechas asignadas y periodos habilitados',
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
            child: _buildQueryContent(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildQueryContent(RegistrationProvider provider) {
    return Query(
      options: QueryOptions(
        document: gql(getDatesQuery),
        variables: {
          'carr': int.tryParse(provider.selectedCareer?.code ?? '0') ?? 0,
          'plan': '1',
          'sem': '1',
          'ano': 2026,
          'nroSerie': 999123,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        if (result.hasException) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 64),
                  const SizedBox(height: 16),
                  const Text('Error al cargar las fechas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(result.exception.toString(), textAlign: TextAlign.center, style: const TextStyle(color: UAGRMTheme.textGrey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: refetch,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final calData = result.data?['calendario'] as Map<String, dynamic>?;
        final matData = result.data?['matIns'] as Map<String, dynamic>?;

        String fetchDiaAsignado;
        if (matData != null) {
          fetchDiaAsignado = '${matData['diaIns'] ?? 'Día 1'} - ${matData['horaIns'] ?? '08:00'}';
        } else {
          fetchDiaAsignado = 'Día Asignado - Pendiente';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAssignedDayBanner(fetchDiaAsignado),
            const SizedBox(height: 24),
            _buildDatesTable(calData),
          ],
        );
      },
    );
  }

  Widget _buildAssignedDayBanner(String assignmentText) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UAGRMTheme.sidebarDeep.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: UAGRMTheme.sidebarDeep, size: isMobile ? 28 : 36),
          ),
          SizedBox(width: isMobile ? 16 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SU DÍA DE INSCRIPCIÓN ASIGNADO',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 10 : 12,
                    color: UAGRMTheme.textGrey,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignmentText,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 20 : 26,
                    fontWeight: FontWeight.w900,
                    color: UAGRMTheme.sidebarDeep,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesTable(Map<String, dynamic>? calData) {
    final isMobile = Responsive.isMobile(context);
    final labels = isMobile
        ? const ['PROCESO', 'PERIODO', 'DÍA']
        : const ['PROCESO', 'PERIODO', 'F. INICIO', 'F. FIN', 'DÍA', 'FECHA EST.'];
    final flexValues = isMobile ? [3, 6, 2] : [2, 4, 3, 3, 2, 3];

    return StandardTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined, color: UAGRMTheme.sidebarBg, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Fechas Habilitadas por la Carrera',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: UAGRMTheme.sidebarBg,
                  ),
                ),
              ],
            ),
          ),
          StandardFlexHeader(labels: labels, flexValues: flexValues),
          _buildRow('Inscripcion', '1/2026 Semestre Regular', calData?['fecIniIns'] ?? '-', calData?['fecFinIns'] ?? '-', '1', calData?['fecIniIns'] ?? '-', false, isMobile, flexValues),
          _buildRow('Rezagados', '1/2026 Semestre Regular', calData?['fecIniRez'] ?? '-', calData?['fecFinRez'] ?? '-', '1', calData?['fecIniRez'] ?? '-', false, isMobile, flexValues),
          _buildRow('Adicion', '1/2026 Semestre Regular', calData?['fecIniAdi'] ?? '-', calData?['fecFinAdi'] ?? '-', '1', calData?['fecIniAdi'] ?? '-', false, isMobile, flexValues),
          _buildRow('Retiro', '1/2026 Semestre Regular', calData?['fecIniRet'] ?? '-', calData?['fecFinRet'] ?? '-', '1', calData?['fecIniRet'] ?? '-', true, isMobile, flexValues),
        ],
      ),
    );
  }

  Widget _buildRow(String proceso, String periodo, String inicio, String fin, String dia, String estudiante, bool isLast, bool isMobile, List<int> flexValues) {
    return StandardFlexRow(
      flexValues: flexValues,
      isLast: isLast,
      cells: [
        AppProcessBadge(proceso),
        tableText(periodo, isMobile, bold: true),
        if (!isMobile) tableText(inicio, isMobile),
        if (!isMobile) tableText(fin, isMobile),
        Center(
          child: Text(dia, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: UAGRMTheme.primaryBlue, fontSize: isMobile ? 13 : 15)),
        ),
        if (!isMobile) tableText(estudiante, isMobile),
      ],
    );
  }
}
