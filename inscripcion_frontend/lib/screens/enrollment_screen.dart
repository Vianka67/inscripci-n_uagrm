import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  @override
  void initState() {
    super.initState();
    // Configurar barra de estado para esta pantalla
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Iconos claros para fondo azul
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  String? selectedPeriod;

  // Periodos de ejemplo (hardcoded por ahora)
  final List<Map<String, dynamic>> periods = [
    {'nombre': '1/2026', 'activo': true},
    {'nombre': '3/2026', 'activo': false},
  ];

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
        title: const Text('Inscripción'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.app_registration, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Selecciona el Periodo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Period List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: periods.length,
                itemBuilder: (context, index) {
                  final period = periods[index];
                  final periodName = period['nombre'] ?? '';
                  final isActive = period['activo'] ?? false;
                  final isSelected = selectedPeriod == periodName;

                  return GestureDetector(
                    onTap: isActive
                        ? () {
                            setState(() => selectedPeriod = periodName);
                            _showSubjectsForPeriod(context, studentRegister ?? '');
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? UAGRMTheme.primaryBlue
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? UAGRMTheme.primaryBlue.withOpacity(0.2)
                                : Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? UAGRMTheme.primaryBlue.withOpacity(0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: isActive
                                  ? UAGRMTheme.primaryBlue
                                  : UAGRMTheme.textGrey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  periodName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: UAGRMTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isActive ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isActive
                                        ? UAGRMTheme.successGreen
                                        : UAGRMTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: UAGRMTheme.primaryBlue,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectsForPeriod(BuildContext context, String registro) {
    final provider = context.read<RegistrationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: UAGRMTheme.primaryBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Materias Disponibles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Query(
                  options: QueryOptions(
                    document: gql(getSubjectsQuery),
                    variables: {
                      'registro': registro,
                      'codigoCarrera': provider.selectedCareer?.code,
                    },
                  ),
                  builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
                    if (result.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (result.hasException) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Error al cargar materias',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.exception.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: refetch,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final subjectsData = result.data?['materiasHabilitadas'] as List<dynamic>? ?? [];

                    if (subjectsData.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 64, color: UAGRMTheme.textGrey),
                              SizedBox(height: 16),
                              Text(
                                'No hay materias disponibles',
                                style: TextStyle(fontSize: 16, color: UAGRMTheme.textGrey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: subjectsData.length,
                      itemBuilder: (context, index) {
                        final subject = subjectsData[index];
                        final materia = subject['materia'];
                        final isEnabled = subject['habilitada'] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isEnabled
                                  ? UAGRMTheme.successGreen
                                  : UAGRMTheme.textGrey,
                              child: Text(
                                '${subject['semestre']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              materia['nombre'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Código: ${materia['codigo']} • ${materia['creditos']} créditos'),
                            trailing: isEnabled
                                ? ElevatedButton(
                                    onPressed: () {
                                      // TODO: Implement enrollment logic
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Funcionalidad de inscripción próximamente'),
                                        ),
                                      );
                                    },
                                    child: const Text('Inscribir'),
                                  )
                                : const Chip(
                                    label: Text('No habilitada'),
                                    backgroundColor: Colors.grey,
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
