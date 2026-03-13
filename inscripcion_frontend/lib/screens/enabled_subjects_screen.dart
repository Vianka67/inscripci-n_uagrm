import 'package:inscripcion_frontend/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/models/subject.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/widgets/web_page_header.dart';

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

    final bool isTabletOrDesktop = Responsive.isTabletOrDesktop(context);
    if (isTabletOrDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebPageHeader(
                title: 'Materias Habilitadas',
                icon: Icons.book_outlined,
                subtitle: 'Materias disponibles para inscripción este periodo',
              ),
              Expanded(
                child: _buildQuery(context, provider, studentRegister, isWeb: isTabletOrDesktop),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Materias Habilitadas'), centerTitle: true),
      body: _buildQuery(context, provider, studentRegister, isWeb: isTabletOrDesktop),
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
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${result.exception.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
              ],
            ),
          );
        }

        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
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

        if (isWeb) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen
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
                    const SizedBox(height: 16),

                    // Tabla web
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: UAGRMTheme.primaryBlue,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 80, child: Text('CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
                                Expanded(child: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
                                SizedBox(width: 80, child: Text('CRÉDITOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
                                SizedBox(width: 80, child: Text('SEMESTRE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
                                SizedBox(width: 100, child: Text('TIPO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          // Filas
                          ...subjects.asMap().entries.map((entry) {
                            final i = entry.key;
                            final subject = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(subject.code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600, color: UAGRMTheme.primaryBlue)),
                                  ),
                                  Expanded(child: Text(subject.name, style: const TextStyle(fontSize: 13))),
                                  SizedBox(width: 80, child: Text('${subject.credits}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                  SizedBox(width: 80, child: Text('${subject.semester}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                  SizedBox(
                                    width: 100,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: subject.isRequired ? UAGRMTheme.primaryBlue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: subject.isRequired ? UAGRMTheme.primaryBlue.withValues(alpha: 0.4) : Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          subject.isRequired ? 'Obligatoria' : 'Electiva',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: subject.isRequired ? UAGRMTheme.primaryBlue : UAGRMTheme.textGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Móvil: diseño original con cards
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: UAGRMTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, color: UAGRMTheme.primaryBlue),
                ),
                title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Código: ${subject.code}'),
                    Text('Semestre: ${subject.semester}'),
                    Row(
                      children: [
                        Text('${subject.credits} créditos'),
                        const SizedBox(width: 8),
                        if (subject.isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: UAGRMTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Obligatoria', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey)),
        ],
      ),
    );
  }
}
