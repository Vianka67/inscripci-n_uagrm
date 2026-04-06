import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/modules/inscripcion/widgets/web_page_header.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/modules/inscripcion/widgets/schedule_grid_view.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  final String getEnrollmentScheduleQuery = """
    query GetEnrollmentSchedule(\$registro: String!, \$codigoCarrera: String) {
      inscripcionCompleta(registro: \$registro, codigoCarrera: \$codigoCarrera) {
        id
        materiasInscritas {
          materia {
            codigo
            nombre
          }
          oferta {
            grupo
            horario
          }
        }
      }
    }
  """;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister ?? '';
    final codigoCarrera = provider.selectedCareer?.code;
    final isLarge = Responsive.isTabletOrDesktop(context);

    return MainLayout(
      title: 'Horario Semanal',
      subtitle: 'Distribución de tus materias inscritas por día y hora',
      child: _buildQuery(context, studentRegister, codigoCarrera, isLarge),
    );
  }

  Widget _buildQuery(BuildContext context, String registro, String? codigoCarrera, bool isLarge) {
    return Query(
      options: QueryOptions(
        document: gql(widget.getEnrollmentScheduleQuery),
        variables: {'registro': registro, 'codigoCarrera': codigoCarrera},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: ${result.exception.toString()}',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
                ],
              ),
            ),
          );
        }

        final data = result.data?['inscripcionCompleta'];
        final materias = (data?['materiasInscritas'] as List<dynamic>?) ?? [];

        return ScheduleGridView(materias: materias, isLarge: isLarge);
      },
    );
  }
}
