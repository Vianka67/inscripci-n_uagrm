import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/student.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

class MainPanelScreen extends StatelessWidget {
  const MainPanelScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;
    final selectedCareer = provider.selectedCareer;

    if (studentRegister == null || studentRegister.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: UAGRMTheme.primaryBlue),
              const SizedBox(height: 24),
              const Text('Cargando sesión...', style: TextStyle(color: UAGRMTheme.textGrey)),
              const SizedBox(height: 32),
              // Botón de rescate si el estado se queda trabado
              TextButton.icon(
                onPressed: () {
                  provider.clearSelection();
                  Navigator.of(context).pushReplacementNamed('/');
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Volver al Login'),
                style: TextButton.styleFrom(foregroundColor: UAGRMTheme.errorRed),
              ),
            ],
          ),
        ),
      );
    }

    return MainLayout(
      title: 'Dashboard',
      child: Query(
        options: QueryOptions(
          document: gql(getPanelQuery),
          variables: {
            'registro': studentRegister,
            'codigoCarrera': selectedCareer?.code,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text('Error de conexión:\n${result.exception.toString()}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
                ],
              ),
            );
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = result.data?['panelEstudiante'];
          if (data == null) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final student = Student.fromJson(data);
          final optionsJson = data['opcionesDisponibles'] ?? {};
          final periodJson = data['periodoActual'];
          final options = PanelOptions.fromJson(optionsJson, periodJson);

          // Sincronizar nombre con el proveedor de estado
          if (provider.studentName == null || provider.studentName!.isEmpty || provider.studentName == 'Estudiante UAGRM') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.setStudentRegister(student.register, name: student.fullName);
            });
          }

          return _buildDashboardContent(context, student, selectedCareer?.name, options);
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, Student student, String? careerName, PanelOptions options) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.isTabletOrDesktop(context) ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, ${student.fullName.split(' ').first} ${student.fullName.split(' ').length > 1 ? student.fullName.split(' ')[1] : ''}',
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: UAGRMTheme.textDark, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            careerName != null ? 'Seleccione una opción para continuar' : 'Seleccione una carrera para continuar',
            style: const TextStyle(fontSize: 14, color: UAGRMTheme.textGrey),
          ),
          const SizedBox(height: 32),

          if (careerName == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D)), // Ambar borde
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Seleccione una carrera en el menú lateral para acceder a las opciones.',
                      style: TextStyle(color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],


          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 1;
              if (constraints.maxWidth > 500) cols = 2;
              if (constraints.maxWidth > 800) cols = 3;
              if (constraints.maxWidth > 1100) cols = 4;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.4, // Taller cards to avoid overflow
                children: _buildCards(context, options, isEnabled: careerName != null),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context, PanelOptions options, {required bool isEnabled}) {
    return [
      _DashboardCard(
        title: 'Registrar Materias',
        subtitle: 'Inscribir, adicionar o retirar materias',
        icon: Icons.menu_book_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/pre-enrollment'),
      ),
      _DashboardCard(
        title: 'Materias Habilitadas',
        subtitle: 'Ver materias disponibles para inscripción',
        icon: Icons.checklist_rtl_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/enabled-subjects'),
      ),
      _DashboardCard(
        title: 'Fecha/Hora Inscripción',
        subtitle: 'Consultar fechas asignadas',
        icon: Icons.calendar_month_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/enrollment-dates'),
      ),
      _DashboardCard(
        title: 'Boleta de Inscripción',
        subtitle: 'Ver e imprimir boleta',
        icon: Icons.description_outlined,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/enrollment-slip'),
      ),
      _DashboardCard(
        title: 'Estado de Bloqueos',
        subtitle: 'Consultar bloqueos activos',
        icon: Icons.lock_outline,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/blocked-status'),
      ),
      _DashboardCard(
        title: 'Transacciones',
        subtitle: 'Historial de transacciones',
        icon: Icons.attach_money_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/transactions'),
      ),
      _DashboardCard(
        title: 'Calendario Académico',
        subtitle: 'Fechas importantes del semestre',
        icon: Icons.date_range_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/calendar'),
      ),
      _DashboardCard(
        title: 'Maestro de Ofertas',
        subtitle: 'Todas las materias ofertadas',
        icon: Icons.grid_view_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/maestro'),
      ),
      _DashboardCard(
        title: 'Pagos',
        subtitle: 'Realizar pagos pendientes',
        icon: Icons.payment_rounded,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/payments'),
      ),
      _DashboardCard(
        title: 'Anulaciones',
        subtitle: 'Historial de anulación de materias',
        icon: Icons.undo_outlined,
        isEnabled: isEnabled,
        onTap: () => Navigator.pushNamed(context, '/anulaciones'),
      ),
    ];
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
      elevation: 0,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(20), // Ajustado de 24 a 20 para dar espacio al texto
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: UAGRMTheme.sidebarDeep, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: UAGRMTheme.textDark, letterSpacing: 0.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
