import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/career.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/utils/time_formatter.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/schedule_validator.dart';
import 'package:inscripcion_frontend/modules/inscripcion/widgets/schedule_grid_view.dart';
import 'package:inscripcion_frontend/shared/utils/pdf_generator.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  // Auto-selección del primer periodo para carga directa
  String? selectedPeriod = '1/2026';

  // Filtros
  String selectedTurno = 'TODOS';
  String selectedCupos = 'TODOS';
  String? selectedDocente = 'TODOS';
  String selectedGrupo = 'TODOS';

  // Selección de materias y grupos
  Set<String> selectedSubjectCodes = {};
  Map<String, dynamic> selectedGroupsPerSubject = {}; // materia_codigo -> oferta_data

  // Estado del flujo de inscripción
  bool _isReviewing = false;
  bool _confirmed = false;
  bool _isConfirming = false;

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

  final List<Map<String, dynamic>> periods = [
    {'nombre': '1/2026', 'activo': true},
  ];

  final String getOfertasQuery = """
    query GetOfertasFiltered(
      \$codigoCarrera: String,
      \$tieneCupo: Boolean,
      \$docente: String,
      \$grupo: String
    ) {
      ofertasMateria(
        codigoCarrera: \$codigoCarrera,
        tieneCupo: \$tieneCupo,
        docente: \$docente,
        grupo: \$grupo
      ) {
        id
        grupo
        docente
        horario
        cupoMaximo
        cupoActual
        cuposDisponibles
        materiaCodigo
        materiaNombre
      }
    }
  """;

  final String confirmMutation = """
    mutation ConfirmarInscripcion(
      \$registro: String!,
      \$codigoCarrera: String!,
      \$ofertaIds: [Int!]!
    ) {
      confirmarInscripcion(
        registro: \$registro,
        codigoCarrera: \$codigoCarrera,
        ofertaIds: \$ofertaIds
      ) {
        ok
        mensaje
      }
    }
  """;

  Future<void> _handleConfirmar(String registro, String codigoCarrera) async {
    if (selectedGroupsPerSubject.isEmpty) return;

    setState(() => _isConfirming = true);

    try {
      final client = GraphQLProvider.of(context).value;
      final ofertaIds = selectedGroupsPerSubject.values
          .map((g) => int.tryParse(g['id']?.toString() ?? '0') ?? 0)
          .toList();

      final result = await client.mutate(
        MutationOptions(
          document: gql(confirmMutation),
          variables: {
            'registro': registro,
            'codigoCarrera': codigoCarrera,
            'ofertaIds': ofertaIds,
          },
        ),
      );

      if (!mounted) return;

      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.exception.toString()}'),
            backgroundColor: UAGRMTheme.errorRed,
          ),
        );
        setState(() => _isConfirming = false);
        return;
      }

      final data = result.data?['confirmarInscripcion'];
      final ok = data?['ok'] == true;
      final mensaje = data?['mensaje'] ?? 'Sin respuesta del servidor';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: ok ? UAGRMTheme.successGreen : UAGRMTheme.errorRed,
        ),
      );

      if (ok) {
        setState(() {
          _confirmed = true;
          _isConfirming = false;
        });
      } else {
        setState(() => _isConfirming = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: UAGRMTheme.errorRed,
          ),
        );
        setState(() => _isConfirming = false);
      }
    }
  }

  // Consulta para obtener las carreras del estudiante
  final String getCareersForEnrollmentQuery = """
    query GetCarrerasEnrollment(\$registro: String!) {
      misCarreras(registro: \$registro) {
        carrera {
          codigo
          nombre
          facultad
          duracionSemestres
        }
      }
    }
  """;

  String _getTurno(String? horario) {
    if (horario == null || horario.isEmpty) return 'MAÑANA';
    final h = horario.toUpperCase();
    if (h.contains('13:') || h.contains('14:') || h.contains('15:') || h.contains('16:') || h.contains('17:')) return 'TARDE';
    if (h.contains('18:') || h.contains('19:') || h.contains('20:') || h.contains('21:') || h.contains('22:')) return 'NOCHE';
    return 'MAÑANA';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;
    final codigoCarrera = provider.selectedCareer?.code;

    // Si no hay carrera seleccionada, se muestra el selector de carreras
    if (codigoCarrera == null || codigoCarrera.isEmpty) {
      return MainLayout(
        title: 'Inscripción',
        subtitle: 'Selecciona tu carrera para continuar',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: _buildCareerSelector(context, studentRegister ?? ''),
          ),
        ),
      );
    }

    return MainLayout(
      title: 'Inscripción',
      subtitle: 'Selecciona y confirma tus materias para este periodo',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1000,
                maxHeight: constraints.maxHeight, // Restricción de altura para evitar desbordamiento
              ),
              child: _buildEnrollmentFlow(studentRegister ?? '', codigoCarrera),
            ),
          );
        },
      ),
    );
  }

  /// Widget para seleccionar carrera
  Widget _buildCareerSelector(BuildContext context, String registro) {
    return Query(
      options: QueryOptions(
        document: gql(getCareersForEnrollmentQuery),
        variables: {'registro': registro},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              StandardTableContainer(
                child: Column(
                  children: [
                    StandardTableHeader(
                      children: const [
                        Icon(Icons.school_outlined, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StandardHeaderCell('Seleccionar Carrera'),
                              SizedBox(height: 2),
                              Text('Elige la carrera para inscribir materias',
                                  style: TextStyle(fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Listado de carreras
              Builder(builder: (ctx) {
                if (result.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (result.hasException) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Error al cargar carreras',
                                style: TextStyle(color: Colors.red.shade800))),
                        TextButton(
                            onPressed: refetch,
                            child: const Text('Reintentar')),
                      ],
                    ),
                  );
                }

                final carrerasData =
                    result.data?['misCarreras'] as List<dynamic>? ?? [];

                if (carrerasData.isEmpty) {
                  return const Center(
                    child: Text('No tienes carreras registradas.'),
                  );
                }

                return Column(
                  children: carrerasData.map<Widget>((item) {
                    final c = item['carrera'] as Map<String, dynamic>;
                    final codigo = c['codigo']?.toString() ?? '';
                    final nombre = c['nombre']?.toString() ?? '';
                    final facultad = c['facultad']?.toString() ?? '';

                    return InkWell(
                      onTap: () {
                        context.read<RegistrationProvider>().selectCareer(
                              Career(
                                code: codigo,
                                name: nombre,
                                faculty: facultad,
                                durationSemesters: c['duracionSemestres'] ?? 9,
                              ),
                            );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: UAGRMTheme.primaryBlue
                                  .withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: UAGRMTheme.primaryBlue
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.book_outlined,
                                  color: UAGRMTheme.primaryBlue, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: UAGRMTheme.textDark)),
                                  const SizedBox(height: 2),
                                  Text(facultad,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: UAGRMTheme.textGrey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: UAGRMTheme.primaryBlue),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebPeriodSelection() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [UAGRMTheme.primaryBlue, UAGRMTheme.sidebarBg],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccionar Periodo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Elige el periodo académico para continuar con la inscripción.',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...periods.map((period) {
                final periodName = period['nombre'] ?? '';
                final isActive = period['activo'] ?? false;
                return InkWell(
                  onTap: isActive ? () => setState(() => selectedPeriod = periodName) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isActive ? UAGRMTheme.primaryBlue.withValues(alpha: 0.3) : Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.calendar_today, color: UAGRMTheme.primaryBlue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(periodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(isActive ? 'Periodo activo — haz clic para continuar' : 'Inactivo',
                                  style: TextStyle(fontSize: 12, color: isActive ? UAGRMTheme.successGreen : UAGRMTheme.textGrey)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: isActive ? UAGRMTheme.primaryBlue : Colors.grey.shade300),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [UAGRMTheme.primaryBlue, UAGRMTheme.sidebarBg],
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.app_registration, size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Selecciona el Periodo',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: periods.length,
            itemBuilder: (context, index) {
              final period = periods[index];
              final periodName = period['nombre'] ?? '';
              final isActive = period['activo'] ?? false;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.calendar_today, color: UAGRMTheme.primaryBlue),
                  title: Text(periodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(color: isActive ? UAGRMTheme.successGreen : UAGRMTheme.textGrey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: isActive ? () => setState(() => selectedPeriod = periodName) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentFlow(String registro, String codigoCarrera) {
    return Column(
      children: [
        // Contenedor principal de la inscripción

        // Contenido Principal
        Expanded(
          child: Query(
            options: QueryOptions(
              document: gql(getOfertasQuery),
              variables: {
                'codigoCarrera': codigoCarrera,
                'tieneCupo': null,
                'docente': null,
                'grupo': null,
              },
            ),
            builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
              if (result.isLoading) return const Center(child: CircularProgressIndicator());
              if (result.hasException) return _buildError(result.exception.toString(), refetch);

              final List<dynamic> allOfertas;
              final List<dynamic> filteredOfertas;

              try {
                allOfertas = result.data?['ofertasMateria'] as List<dynamic>? ?? [];

                // Filtrado local dinámico para la interfaz
                filteredOfertas = allOfertas.where((o) {
                  final turnoCalc = _getTurno(o['horario']?.toString());
                  final matchTurno = selectedTurno == 'TODOS' || (turnoCalc == selectedTurno);
                  final matchDocente = selectedDocente == 'TODOS' || (o['docente'] == selectedDocente);
                  final matchGrupo = selectedGrupo == 'TODOS' || (o['grupo'] == selectedGrupo);
                  final matchCupo = selectedCupos == 'TODOS' || (selectedCupos == 'CON CUPO' ? ((o['cuposDisponibles'] ?? 0) > 0) : ((o['cuposDisponibles'] ?? 0) == 0));
                  return matchTurno && matchDocente && matchGrupo && matchCupo;
                }).toList();
              } catch (e) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
                        const SizedBox(height: 16),
                        const Text('Error al procesar ofertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Detalle técnico: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: refetch, child: const Text('Reintentar carga')),
                      ],
                    ),
                  ),
                );
              }

              // Opciones únicas para los filtros
              final List<String> uniqueTurnos = ['TODOS', 'MAÑANA', 'TARDE', 'NOCHE'];
              final List<String> uniqueDocentes = ['TODOS', ...allOfertas.map((o) => o['docente']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort()];
              final List<String> uniqueGrupos = ['TODOS', ...allOfertas.map((o) => o['grupo']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort()];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                        // Estado: Selección de materias
                        if (!_confirmed && !_isReviewing) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: Responsive.isTabletOrDesktop(context) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))] : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Título y controles de navegación
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Inscripción - $selectedPeriod Semestre Regular',
                                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: UAGRMTheme.textDark, letterSpacing: -0.2),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.remove, size: 16, color: UAGRMTheme.textDark),
                                        label: const Text('Volver', style: TextStyle(color: UAGRMTheme.textDark)),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Barra de filtros
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.filter_alt_outlined, color: UAGRMTheme.textGrey, size: 20),
                                        const SizedBox(width: 16),
                                        _buildDropdownFilter('Todos los turnos', selectedTurno, uniqueTurnos, (v) => setState(() => selectedTurno = v!)),
                                        const SizedBox(width: 8),
                                        _buildDropdownFilter('Todos los docentes', selectedDocente ?? 'TODOS', uniqueDocentes, (v) => setState(() => selectedDocente = v!)),
                                        const SizedBox(width: 8),
                                        _buildDropdownFilter('Todos los grupos', selectedGrupo, uniqueGrupos, (v) => setState(() => selectedGrupo = v!)),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _seleccionarMateriaAleatoria(filteredOfertas),
                                          icon: const Icon(Icons.auto_awesome, size: 16),
                                          label: const Text('Auto-Selección', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: UAGRMTheme.successGreen,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Tabla
                                _buildFlatSubjectsTable(filteredOfertas),
                              ],
                            ),
                          ),
                        ],

                        // Estado: Revisión de selección
                        if (!_confirmed && _isReviewing) ...[
                          _buildReviewSelectionCard(registro, codigoCarrera), 
                        ],

                        // Estado: Inscripción confirmada
                        if (_confirmed) ...[
                          _buildConfirmationSuccess(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Barra "Sticky" en la parte inferior cuando hay elementos seleccionados y estamos en selección
                if (!_confirmed && !_isReviewing && selectedSubjectCodes.isNotEmpty)
                  _buildStickyConfirmBar(),

                  // Botón confirmar original cuando nada seleccionado
                  if (!_confirmed && selectedSubjectCodes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildFinalActions(registro, codigoCarrera),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String hint, String currentValue, List<String> options, Function(String?) onChanged) {
    final displayText = currentValue == 'TODOS' ? hint : currentValue;
    return IntrinsicWidth(
      child: Container(
        height: 38,
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: currentValue == 'TODOS' ? null : currentValue,
            hint: Text(displayText, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark)),
            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: UAGRMTheme.textGrey),
            items: options.map((String value) {
              final text = value == 'TODOS' ? hint : value;
              return DropdownMenuItem<String>(
                value: value == 'TODOS' ? null : value,
                child: Text(text, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark)),
              );
            }).toList(),
            onChanged: (val) => onChanged(val ?? 'TODOS'),
          ),
        ),
      ),
    );
  }

  /// Muestra un SnackBar en la parte SUPERIOR de la pantalla
  void _showTopSnackBar(String message, {Color color = const Color(0xFFB71C1C)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 130,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _seleccionarMateriaAleatoria(List<dynamic> ofertasDisponibles) {
    final Map<String, List<dynamic>> ofertasPorMateria = {};
    for (var o in ofertasDisponibles) {
      if ((o['cuposDisponibles'] ?? 0) <= 0) continue;
      
      final codigo = o['materiaCodigo']?.toString() ?? '';
      if (codigo.isEmpty || selectedSubjectCodes.contains(codigo)) continue;

      ofertasPorMateria.putIfAbsent(codigo, () => []).add(o);
    }

    if (ofertasPorMateria.isEmpty) {
      _showTopSnackBar('No hay más materias con cupo para seleccionar automáticamente.', color: Colors.blue);
      return;
    }

    bool algoSeleccionado = false;
    for (var entry in ofertasPorMateria.entries) {
      final codigoMateria = entry.key;
      final ofertas = entry.value..shuffle();

      for (var ofertaRandom in ofertas) {
        final clashMsg = ScheduleValidator.checkClash(
          ofertaRandom['horario'] ?? '',
          ofertaRandom['materiaNombre'] ?? codigoMateria,
          selectedGroupsPerSubject,
        );

        if (clashMsg == null) {
          setState(() {
            selectedSubjectCodes.add(codigoMateria);
            selectedGroupsPerSubject[codigoMateria] = ofertaRandom;
          });
          algoSeleccionado = true;
          break;
        }
      }
    }

    if (!algoSeleccionado) {
       _showTopSnackBar('No se encontró una combinación de materias sin choques de horario.', color: Colors.orange.shade800);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completado con materias sin choques de horario.'), backgroundColor: UAGRMTheme.successGreen));
    }
  }

  Widget _buildFlatSubjectsTable(List<dynamic> ofertas) {
    final isWeb = Responsive.isTabletOrDesktop(context);
    if (ofertas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('No hay materias disponibles para los filtros aplicados', style: TextStyle(color: UAGRMTheme.textGrey))),
      );
    }
    
    // Proporciones de columnas: [Check, Sigla, Materia, Grupo, Turno, Docente, Horario, Cupo]
    final flexValues = [1, 2, 5, 1, 2, 2, 3, 1];

    return StandardTableContainer(
      minWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardFlexHeader(
            labels: const ['', 'Sigla', 'Asignatura', 'Gru.', 'Turno', 'Docente', 'Horario', 'Cupo'],
            flexValues: flexValues,
          ),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ofertas.length,
            itemBuilder: (context, index) {
              final o = ofertas[index];
              final code = o['materiaCodigo'] ?? '';
              final hayCupo = (o['cuposDisponibles'] ?? 0) > 0;
              final isMateriaSelected = selectedSubjectCodes.contains(code);
              final selectedGroupIdForMateria = isMateriaSelected && selectedGroupsPerSubject[code] != null
                  ? selectedGroupsPerSubject[code]!['id'] 
                  : null;
                  
              final isSelected = isMateriaSelected && selectedGroupIdForMateria == o['id'];
              final isOtherGroupSelected = isMateriaSelected && selectedGroupIdForMateria != o['id'];

              return StandardFlexRow(
                flexValues: flexValues,
                isLast: index == ofertas.length - 1,
                cells: [
                  // Checkbox Column
                  IconButton(
                    onPressed: (!hayCupo) ? null : () {
                      if (isOtherGroupSelected) {
                        _showTopSnackBar('Ya seleccionaste el grupo ${selectedGroupsPerSubject[code]['grupo']} de esta materia', color: Colors.orange.shade800);
                        return;
                      }
                      
                      setState(() {
                        if (isSelected) {
                          selectedSubjectCodes.remove(code);
                          selectedGroupsPerSubject.remove(code);
                        } else {
                          selectedSubjectCodes.add(code);
                          selectedGroupsPerSubject[code] = o;
                        }
                      });
                    },
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: !hayCupo ? Colors.grey.shade200 : (isSelected ? UAGRMTheme.primaryBlue : Colors.grey.shade300),
                      size: 22,
                    ),
                  ),
                  
                  Text(code, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: hayCupo ? UAGRMTheme.textDark : Colors.grey.shade400)),
                  Text(o['materiaNombre'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: hayCupo ? UAGRMTheme.textDark : Colors.grey.shade400)),
                  Text(o['grupo'] ?? '', style: TextStyle(fontSize: 13, color: hayCupo ? UAGRMTheme.textDark : Colors.grey.shade400)),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: hayCupo ? 1.0 : 0.4,
                      child: AppTurnoBadge(o['horario']?.toString() ?? ''),
                    ),
                  ),
                  
                  Text(o['docente'] ?? '', style: TextStyle(fontSize: 13, color: hayCupo ? UAGRMTheme.textDark : Colors.grey.shade400), maxLines: 2, overflow: TextOverflow.ellipsis),
                  
                  Text(
                    TimeFormatter.formatHorario(o['horario'] ?? ''), 
                    style: TextStyle(fontSize: 12, color: hayCupo ? UAGRMTheme.textGrey : Colors.grey.shade300, fontWeight: FontWeight.w500)
                  ),
                  
                  Center(
                    child: AppCupoBadge(o['cuposDisponibles'] as int? ?? 0),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCleanHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: UAGRMTheme.textDark),
      ),
    );
  }

  Widget _buildBlueHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
      ),
    );
  }

  Widget _buildCleanCellText(String text, bool active) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(text, style: TextStyle(fontSize: 13, color: active ? UAGRMTheme.textDark : Colors.grey.shade400)),
      ),
    );
  }

  Widget _buildReviewSelectionCard(String registro, String codigoCarrera) {
    return StandardTableContainer(
      minWidth: 700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Confirmar Adición', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark)),
          ),
          Column(
            children: [
              StandardFlexHeader(
                labels: const ['Sigla', 'Asignatura', 'Gru.', 'Turno', 'Docente', 'Horario', 'Aula'],
                flexValues: const [1, 4, 1, 2, 2, 3, 1],
              ),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedSubjectCodes.length,
                itemBuilder: (context, index) {
                  final code = selectedSubjectCodes.elementAt(index);
                  final g = selectedGroupsPerSubject[code];
                  if (g == null) return const SizedBox.shrink();

                  return StandardFlexRow(
                    flexValues: const [1, 4, 1, 2, 2, 3, 1],
                    isLast: index == selectedSubjectCodes.length - 1,
                    cells: [
                      Text(code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: UAGRMTheme.textDark)),
                      Text(g['materiaNombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: UAGRMTheme.textDark)),
                      Text(g['grupo'] ?? '', style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark)),
                      
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppTurnoBadge(g['horario']?.toString() ?? ''),
                      ),
                      
                      Text(g['docente'] ?? '', style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                      
                      Text(
                        TimeFormatter.formatHorario(g['horario'] ?? ''), 
                        style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey, fontWeight: FontWeight.w500)
                      ),
                      
                      const Text('Aula 101', style: TextStyle(fontSize: 13, color: UAGRMTheme.textDark)),
                    ],
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isReviewing = false),
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('Modificar', style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: UAGRMTheme.sidebarDeep,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConfirming ? null : () => _handleConfirmar(registro, codigoCarrera),
                    icon: _isConfirming
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_isConfirming ? 'Confirmando...' : 'Confirmar Adición', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UAGRMTheme.sidebarDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Listado de grupos ya inscritos
  Widget _buildConfirmedGroupsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GRUPOS INSCRITOS',
          style: TextStyle(fontWeight: FontWeight.bold, color: UAGRMTheme.primaryBlue),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: Responsive.isTabletOrDesktop(context) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FixedColumnWidth(60),
                  1: FixedColumnWidth(140),
                  2: FixedColumnWidth(60),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(120),
                  5: FixedColumnWidth(50),
                },
                children: [
                  _buildTableHeader(['SIGLA', 'MATERIA', 'GRUPO', 'DOCENTE', 'HORARIO', 'CUPO']),
                  ...selectedSubjectCodes.map((code) {
                    final g = selectedGroupsPerSubject[code];
                    if (g == null) {
                      return const TableRow(
                        children: [SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox()],
                      );
                    }
                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(code, style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(g['materiaNombre'] ?? '', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(g['grupo'] ?? '', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(g['docente'] ?? '', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  AppTurnoBadge(g['horario'] ?? ''),
                                  Text(
                                    TimeFormatter.formatHorario(g['horario'] ?? ''), 
                                    style: const TextStyle(fontSize: 10)
                                  ),
                              ]
                            )
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ((g['cuposDisponibles'] ?? 0) > 0) ? UAGRMTheme.successGreen.withValues(alpha: 0.1) : UAGRMTheme.errorRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${g['cuposDisponibles'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ((g['cuposDisponibles'] ?? 0) > 0) ? UAGRMTheme.successGreen : UAGRMTheme.errorRed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }



  /// Panel de éxito post-confirmación
  Widget _buildConfirmationSuccess() {
    final int n = selectedSubjectCodes.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Fondo verde clarito
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)), // Borde verde
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22C55E), width: 3),
            ),
            child: const Icon(Icons.check, size: 48, color: Color(0xFF22C55E)),
          ),
          const SizedBox(height: 24),
          Text(
            'Adición Exitosa',
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: UAGRMTheme.textDark, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Se registraron $n materia(s) correctamente.',
            style: const TextStyle(fontSize: 14, color: UAGRMTheme.textGrey),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/enrollment-slip'),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Imprimir Boleta de Adición', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UAGRMTheme.sidebarDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton(
                onPressed: () => setState(() {
                  selectedSubjectCodes.clear();
                  selectedGroupsPerSubject.clear();
                  _confirmed = false;
                  _isReviewing = false;
                }),
                child: const Text('Nueva Adición', style: TextStyle(fontSize: 14, color: UAGRMTheme.textDark)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Panel sticky inferior — resumen de selección antes de confirmar
  Widget _buildStickyConfirmBar() {
    final int n = selectedSubjectCodes.length;
    // Cálculo de créditos totales
    final int totalCreds = selectedGroupsPerSubject.values
        .fold(0, (sum, g) => sum + ((g['creditos'] as int?) ?? 0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de materias seleccionadas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: UAGRMTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_box, color: UAGRMTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$n materia${n == 1 ? '' : 's'}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: UAGRMTheme.primaryBlue,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (totalCreds > 0)
                      Text(
                        '$totalCreds créditos',
                        style: const TextStyle(fontSize: 11, color: UAGRMTheme.textGrey),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    selectedSubjectCodes.clear();
                    selectedGroupsPerSubject.clear();
                  }),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: UAGRMTheme.textGrey),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _isReviewing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UAGRMTheme.sidebarDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      'Confirmar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  TableRow _buildTableHeader(List<String> labels) {
    return TableRow(
      decoration: const BoxDecoration(
        color: UAGRMTheme.sidebarDeep, // Navy institucional para encabezados
      ),
      children: labels
          .map((l) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(l, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white, letterSpacing: 0.5)),
                ),
              ))
          .toList(),
    );
  }


  Widget _buildFinalActions(String registro, String codigoCarrera) {
    return Row(
      children: [
        TextButton(
          onPressed: () => setState(() {
            selectedSubjectCodes.clear();
            selectedGroupsPerSubject.clear();
          }),
          child: const Text('LIMPIAR'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: (selectedSubjectCodes.isEmpty || _isConfirming)
                ? null
                : () => _handleConfirmar(registro, codigoCarrera),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isConfirming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'CONFIRMAR INSCRIPCIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error, VoidCallback? refetch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: UAGRMTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
