import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';

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
    query GetBlockStatus(\$registro: String!) {
      bloqueoEstudiante(registro: \$registro) {
        bloqueado
        bloqueos {
          motivo
          fechaBloqueo
        }
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final registro = provider.studentRegister ?? '';

    return MainLayout(
      title: 'Transacciones y Bloqueos',
      subtitle: 'Información sobre bloqueos activos en tu cuenta',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildQuery(registro, isLarge: Responsive.isTabletOrDesktop(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildQuery(String registro, {required bool isLarge}) {
    return Query(
      options: QueryOptions(
        document: gql(getBlockStatusQuery),
        variables: {'registro': registro},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
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
                  const Text('Error al cargar datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

        final data = result.data?['bloqueoEstudiante'];
        if (data == null) {
          return const Center(child: Text('No se encontró información de bloqueo.', style: TextStyle(color: UAGRMTheme.textGrey)));
        }

        final bool isBlocked = data['bloqueado'] ?? false;
        final List bloqueos = data['bloqueos'] ?? [];

        return Column(
          children: [
            _buildStatusHeader(isBlocked, isLarge),
            const SizedBox(height: 24),
            if (isBlocked) _buildBlockedDetails(bloqueos, isLarge),
            if (!isBlocked) _buildUnblockedState(),
          ],
        );
      },
    );
  }

  Widget _buildStatusHeader(bool isBlocked, bool isLarge) {
    if (isBlocked) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLarge ? 32 : 24),
        decoration: BoxDecoration(
          color: UAGRMTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UAGRMTheme.errorRed.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.lock, color: UAGRMTheme.errorRed, size: 64),
            SizedBox(height: 16),
            Text(
              'CUENTA BLOQUEADA',
              style: TextStyle(color: UAGRMTheme.errorRed, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            SizedBox(height: 8),
            Text(
              'No puedes realizar procesos de inscripción. Revisa los detalles a continuación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: UAGRMTheme.textDark, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLarge ? 32 : 24),
        decoration: BoxDecoration(
          color: UAGRMTheme.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UAGRMTheme.successGreen.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: UAGRMTheme.successGreen, size: 64),
            SizedBox(height: 16),
            Text(
              'CUENTA HABILITADA',
              style: TextStyle(color: UAGRMTheme.successGreen, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            SizedBox(height: 8),
            Text(
              'No tienes bloqueos activos. Puedes registrar tus materias normalmente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: UAGRMTheme.textDark, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBlockedDetails(List bloqueos, bool isLarge) {
    if (bloqueos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Detalles de Bloqueos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UAGRMTheme.primaryBlue),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bloqueos.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final b = bloqueos[index];
            final motivo = b['motivo'] ?? 'Motivo desconocido';
            final fecha = b['fechaDesbloqueo'];
            
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: UAGRMTheme.errorRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: UAGRMTheme.errorRed, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          motivo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark),
                        ),
                        if (fecha != null && fecha.toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.date_range, size: 14, color: UAGRMTheme.textGrey),
                              const SizedBox(width: 4),
                              Text(
                                'Posible resolución: ${_formatDate(fecha)}',
                                style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnblockedState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Image.asset('assets/images/image_0.jpeg', height: 120, errorBuilder: (_,__,___) => const Icon(Icons.school, size: 80, color: UAGRMTheme.primaryBlue)),
          const SizedBox(height: 24),
          const Text(
            '¡Todo listo!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No encontramos restricciones en tu registro. Puedes proceder al menú de inscripción.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UAGRMTheme.textGrey),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return isoString;
    }
  }
}
