import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/models/subject.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materias Habilitadas'),
        centerTitle: true,
      ),
      body: Query(
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
                  ElevatedButton(
                    onPressed: refetch,
                    child: const Text('Reintentar'),
                  ),
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
                  Text(
                    'No hay materias habilitadas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

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
                      color: UAGRMTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: UAGRMTheme.primaryBlue,
                    ),
                  ),
                  title: Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
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
                              child: const Text(
                                'Obligatoria',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
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
      ),
    );
  }
}
