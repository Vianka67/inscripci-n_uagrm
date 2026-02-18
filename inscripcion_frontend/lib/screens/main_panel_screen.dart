import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/models/student.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/widgets/student_info_header.dart';
import 'package:inscripcion_frontend/widgets/option_button.dart';

class MainPanelScreen extends StatefulWidget {
  const MainPanelScreen({super.key});

  @override
  State<MainPanelScreen> createState() => _MainPanelScreenState();
}

class _MainPanelScreenState extends State<MainPanelScreen> {
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

  final String getPanelQuery = """
    query GetPanel(\$registro: String!, \$codigoCarrera: String) {
      panelEstudiante(registro: \$registro, codigoCarrera: \$codigoCarrera) {
        estudiante {
          registro
          nombreCompleto
        }
        carrera {
          nombre
        }
        semestreActual
        modalidad
        estado
        periodoActual {
          inscripcionesHabilitadas
        }
        opcionesDisponibles {
          fechasInscripcion
          bloqueo
          boleta
          inscripcion
        }
      }
    }
  """;

  void _navigateToSubjects(BuildContext context) {
    Navigator.pushNamed(context, '/enabled-subjects');
  }

  void _navigateToSlip(BuildContext context) {
    Navigator.pushNamed(context, '/enrollment-slip');
  }

  void _navigateToBlocks(BuildContext context) {
    Navigator.pushNamed(context, '/blocked-status');
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('Esta funcionalidad estará disponible próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;

    if (studentRegister == null) {
      return const Scaffold(
        body: Center(child: Text('No se ha proporcionado un registro.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Query(
          options: QueryOptions(
            document: gql(getPanelQuery),
            variables: {
              'registro': studentRegister,
              'codigoCarrera': provider.selectedCareer?.code,
            },
            fetchPolicy: FetchPolicy.networkOnly,
          ),
          builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (result.hasException) {
               return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar panel: \n${result.exception.toString()}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: refetch,
                        child: const Text('Reintentar'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver al inicio'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (result.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = result.data?['panelEstudiante'];
            if (data == null) {
               return const Center(child: Text('No se encontraron datos para este estudiante.'));
            }

            final student = Student.fromJson(data);
            final optionsJson = data['opcionesDisponibles'] ?? {};
            final periodJson = data['periodoActual'];
            final options = PanelOptions.fromJson(optionsJson, periodJson);

            return Column(
              children: [
                // Header Fijo
                StudentInfoHeader(student: student),

                // Grid scrollable
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      OptionButton(
                        icon: Icons.calendar_month,
                        title: 'Fechas de Inscripción',
                        isAvailable: options.inscriptionDates,
                        onTap: () => Navigator.pushNamed(context, '/enrollment-dates'),
                      ),
                      OptionButton(
                        icon: Icons.lock_outline,
                        title: 'Bloqueo',
                        isAvailable: true,
                        hasBadge: options.blocked,
                        badgeText: '!',
                        onTap: () => _navigateToBlocks(context),
                      ),
                      OptionButton(
                        icon: Icons.book_outlined,
                        title: 'Materias habilitadas',
                        isAvailable: options.enabledSubjects,
                        onTap: () => _navigateToSubjects(context),
                      ),
                      OptionButton(
                        icon: Icons.description_outlined,
                        title: 'Boleta',
                        isAvailable: true,
                        onTap: () => _navigateToSlip(context),
                      ),
                      OptionButton(
                        icon: Icons.app_registration,
                        title: 'Inscripción',
                        isAvailable: options.enrollment,
                        onTap: () => Navigator.pushNamed(context, '/enrollment'),
                      ),
                      OptionButton(
                        icon: Icons.info_outline,
                        title: 'No disponible',
                        isAvailable: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
