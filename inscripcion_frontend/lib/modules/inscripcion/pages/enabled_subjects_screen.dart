import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
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
    query GetEnabledSubjects(\$registro: String!, \$codigoCarrera: String) {
      materiasHabilitadas(registro: \$registro, codigoCarrera: \$codigoCarrera) {
        materia {
          codigo
          nombre
          creditos
        }
        semestre
        obligatoria
        habilitada
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _buildQuery(context, provider, studentRegister, isWeb: Responsive.isTabletOrDesktop(context)),
        ),
      ),
    );
  }

  Widget _buildQuery(BuildContext context, RegistrationProvider provider, String? studentRegister, {required bool isWeb}) {
    return Query(
      options: QueryOptions(
        document: gql(getSubjectsQuery),
        variables: {
          'registro': studentRegister ?? '',
          'codigoCarrera': provider.selectedCareer?.code,
        },
        fetchPolicy: FetchPolicy.networkOnly, // Add fetchPolicy to ensure fresh data
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }

        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                Text('Error de carga:\n${result.exception.toString()}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
              ],
            ),
          );
        }

        final subjectsData = result.data?['materiasHabilitadas'] as List<dynamic>? ?? [];
        final subjects = subjectsData.map((data) => Subject.fromJson(data)).toList();

        if (subjects.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay materias habilitadas', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWeb ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _summaryBadge('${subjects.length}', 'materias habilitadas', UAGRMTheme.primaryBlue),
                  const SizedBox(width: 12),
                  _summaryBadge(
                    '${subjects.where((s) => s.isRequired).length}',
                    'obligatorias',
                    UAGRMTheme.errorRed,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Clean UI Table Container
              StandardTableContainer(
                child: Column(
                  children: [
                    // Header — usa AppTableHeader centralizado
                    AppTableHeader(
                      children: [
                        SizedBox(width: isWeb ? 80 : 60, child: const AppHeaderCell('CÓDIGO')),
                        const Expanded(child: AppHeaderCell('ASIGNATURA')),
                        SizedBox(width: isWeb ? 80 : 60, child: const AppHeaderCell('CRÉDS', textAlign: TextAlign.center)),
                        if (isWeb) const SizedBox(width: 80, child: AppHeaderCell('NIVEL', textAlign: TextAlign.center)),
                        SizedBox(width: isWeb ? 100 : 80, child: const AppHeaderCell('TIPO', textAlign: TextAlign.center)),
                      ],
                    ),
                    
                    // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: subjects.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                SizedBox(width: isWeb ? 80 : 60, child: Text(subject.code, style: const TextStyle(fontWeight: FontWeight.w600, color: UAGRMTheme.textDark, fontSize: 13))),
                                Expanded(child: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600, color: UAGRMTheme.textDark, fontSize: 13))),
                                SizedBox(width: isWeb ? 80 : 60, child: Text('${subject.credits}', style: const TextStyle(color: UAGRMTheme.textGrey, fontSize: 13), textAlign: TextAlign.center)),
                                if (isWeb) SizedBox(width: 80, child: Text('${subject.semester}', style: const TextStyle(color: UAGRMTheme.textGrey, fontSize: 13), textAlign: TextAlign.center)),
                                SizedBox(
                                  width: isWeb ? 100 : 80,
                                  child: Center(
                                    child: AppEstadoBadge(
                                      subject.isRequired ? 'Obligatoria' : 'Electiva',
                                      color: subject.isRequired ? UAGRMTheme.errorRed : UAGRMTheme.successGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryBadge(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
