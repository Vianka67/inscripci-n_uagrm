import 'package:flutter/foundation.dart';
import 'package:inscripcion_frontend/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/utils/time_formatter.dart';
import 'package:inscripcion_frontend/widgets/web_page_header.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  String? selectedPeriod;

  // Filtros
  String selectedTurno = 'TODOS';
  String selectedCupos = 'TODOS';
  String? selectedDocente = 'TODOS';
  String selectedGrupo = 'TODOS';

  // Selección de materias y grupos
  Set<String> selectedSubjectCodes = {};
  Map<String, dynamic> selectedGroupsPerSubject = {}; // materia_codigo -> oferta_data

  // Estado de confirmación: null = no confirmado, true/false = en proceso/resultado
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
      \$turno: String,
      \$tieneCupo: Boolean,
      \$docente: String,
      \$grupo: String
    ) {
      ofertasMateria(
        codigoCarrera: \$codigoCarrera,
        turno: \$turno,
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
          .map((g) => int.parse(g['id'].toString()))
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;
    final codigoCarrera = provider.selectedCareer?.code;

    final bool isTabletOrDesktop = Responsive.isTabletOrDesktop(context);
    if (isTabletOrDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebPageHeader(
                title: 'Inscripción',
                icon: Icons.app_registration,
                subtitle: 'Selecciona y confirma tus materias para este periodo',
              ),
              Expanded(
                child: selectedPeriod == null
                    ? _buildWebPeriodSelection()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: _buildEnrollmentFlow(studentRegister ?? '', codigoCarrera ?? ''),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscripción'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: selectedPeriod == null
            ? _buildPeriodSelection()
            : _buildEnrollmentFlow(studentRegister ?? '', codigoCarrera ?? ''),
      ),
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
              // --- Barra azul de título ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
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
              // --- Lista de periodos ---
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
              colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
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
        // Filtros (solo visibles si no está confirmado)
        if (!_confirmed) _buildFiltersSection(),

        // Contenido Principal
        Expanded(
          child: Query(
            options: QueryOptions(
              document: gql(getOfertasQuery),
              variables: {
                'codigoCarrera': codigoCarrera,
                'turno': selectedTurno == 'TODOS' ? null : selectedTurno,
                'tieneCupo': selectedCupos == 'TODOS' ? null : (selectedCupos == 'CON CUPO'),
                'docente': selectedDocente == 'TODOS' ? null : selectedDocente,
                'grupo': selectedGrupo == 'TODOS' ? null : selectedGrupo,
              },
            ),
            builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
              if (result.isLoading) return const Center(child: CircularProgressIndicator());
              if (result.hasException) return _buildError(result.exception.toString(), refetch);

              final ofertas = result.data?['ofertasMateria'] as List<dynamic>? ?? [];

              // Agrupar ofertas por materia
              Map<String, List<dynamic>> subjectsMap = {};
              for (var o in ofertas) {
                final code = o['materiaCodigo'];
                if (!subjectsMap.containsKey(code)) subjectsMap[code] = [];
                subjectsMap[code]!.add(o);
              }
              final distinctSubjects = subjectsMap.keys.toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === ESTADO: SELECCIÓN (antes de confirmar) ===
                    if (!_confirmed) ...[
                      _buildSelectAllHeader(distinctSubjects, subjectsMap),
                      const SizedBox(height: 8),
                      _buildSubjectsTable(distinctSubjects, subjectsMap),
                      const SizedBox(height: 32),
                      _buildFinalActions(registro, codigoCarrera),
                    ],

                    // === ESTADO: CONFIRMADO (solo muestra tabla de grupos confirmados) ===
                    if (_confirmed) ...[
                      _buildConfirmationSuccess(),
                      const SizedBox(height: 16),
                      _buildConfirmedGroupsTable(),
                      const SizedBox(height: 24),
                      _buildResetButton(),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton('Turno', selectedTurno, ['TODOS', 'MAÑANA', 'TARDE', 'NOCHE'],
                (v) => setState(() => selectedTurno = v)),
            _buildFilterButton('Cupos', selectedCupos, ['TODOS', 'CON CUPO', 'SIN CUPO'],
                (v) => setState(() => selectedCupos = v)),
            _buildFilterButton('Docente', selectedDocente ?? 'TODOS', ['TODOS', 'POR DESIGNAR'],
                (v) => setState(() => selectedDocente = v)),
            _buildFilterButton('Grupo', selectedGrupo, ['TODOS', 'AC', 'BD', 'AB', 'D', 'A', 'B', 'C'],
                (v) => setState(() => selectedGrupo = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String current, List<String> options, Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: PopupMenuButton<String>(
        onSelected: onSelect,
        itemBuilder: (context) =>
            options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: current == 'TODOS' ? Colors.white : UAGRMTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: current == 'TODOS' ? Colors.grey.shade300 : UAGRMTheme.primaryBlue),
          ),
          child: Row(
            children: [
              Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(current,
                  style: TextStyle(
                      color: current == 'TODOS' ? UAGRMTheme.textDark : UAGRMTheme.primaryBlue,
                      fontSize: 12)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// Devuelve true si al menos un grupo de la materia tiene cupos disponibles
  bool _tieneCuposDisponibles(List<dynamic> grupos) {
    return grupos.any((g) => (g['cuposDisponibles'] ?? 0) > 0);
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

  /// Encabezado "Seleccionar Todas las Materias" — ahora con lógica real
  Widget _buildSelectAllHeader(List<String> distinctSubjects, Map<String, List<dynamic>> subjectsMap) {
    // Solo contar las materias que tienen cupos disponibles
    final subjectsWithCupo = distinctSubjects.where((code) => _tieneCuposDisponibles(subjectsMap[code]!)).toList();
    final allSelected = subjectsWithCupo.isNotEmpty &&
        subjectsWithCupo.every((code) => selectedSubjectCodes.contains(code));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Seleccione Todas las Materias',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Checkbox(
            value: allSelected,
            activeColor: Colors.white,
            checkColor: UAGRMTheme.primaryBlue,
            side: const BorderSide(color: Colors.white70, width: 1.5),
            onChanged: distinctSubjects.isEmpty
                ? null
                : (val) {
                    if (val == true) {
                      final newSelection = Map<String, dynamic>.from(selectedGroupsPerSubject);
                      final newCodes = Set<String>.from(selectedSubjectCodes);

                      int autoTurno = 0;   // asignadas en un turno alternativo
                      int sinCupo = 0;     // sin ningún grupo disponible

                      for (final code in distinctSubjects) {
                        if (newCodes.contains(code)) continue; // ya estaba seleccionada

                        final grupos = subjectsMap[code]!;
                        // Filtrar grupos con cupo disponible
                        final conCupo = grupos.where((g) => (g['cuposDisponibles'] ?? 0) > 0).toList();

                        if (conCupo.isEmpty) {
                          sinCupo++;
                          continue; // sin cupo en ningún turno
                        }

                        // Buscar el primer grupo con cupo que no choque
                        dynamic bestGroup;
                        bool usedAlternative = false;
                        final firstGroup = conCupo[0];

                        // Primero intentar el primer grupo disponible
                        final clashFirst = ScheduleValidator.checkClash(
                          firstGroup['horario'] ?? '',
                          firstGroup['materiaNombre'] ?? code,
                          newSelection,
                        );

                        if (clashFirst == null) {
                          bestGroup = firstGroup;
                        } else {
                          // El primer grupo choca: buscar en los demás grupos con cupo
                          for (final g in conCupo.skip(1)) {
                            final clash = ScheduleValidator.checkClash(
                              g['horario'] ?? '',
                              g['materiaNombre'] ?? code,
                              newSelection,
                            );
                            if (clash == null) {
                              bestGroup = g;
                              usedAlternative = true;
                              break;
                            }
                          }
                        }

                        if (bestGroup != null) {
                          newCodes.add(code);
                          newSelection[code] = bestGroup;
                          if (usedAlternative) autoTurno++;
                        } else {
                          // Todos los grupos con cupo chocan con el horario actual
                          // Igualmente asignar el primero con cupo (el usuario puede ajustar)
                          newCodes.add(code);
                          newSelection[code] = firstGroup;
                          autoTurno++;
                        }
                      }

                      setState(() {
                        selectedSubjectCodes = newCodes;
                        selectedGroupsPerSubject = newSelection;
                      });

                      // Notificaciones post-setState
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (sinCupo > 0 && autoTurno > 0) {
                          _showTopSnackBar(
                            '$autoTurno materia(s) asignadas en turno alternativo. $sinCupo materia(s) sin cupos disponibles.',
                            color: Colors.orange.shade800,
                          );
                        } else if (sinCupo > 0) {
                          _showTopSnackBar(
                            '$sinCupo materia(s) no tienen cupos disponibles en ningún turno.',
                            color: UAGRMTheme.errorRed,
                          );
                        } else if (autoTurno > 0) {
                          _showTopSnackBar(
                            '$autoTurno materia(s) asignadas automáticamente en un turno alternativo disponible.',
                            color: Colors.blue.shade700,
                          );
                        }
                      });
                    } else {
                      // Deseleccionar todas
                      setState(() {
                        selectedSubjectCodes.clear();
                        selectedGroupsPerSubject.clear();
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsTable(List<String> codes, Map<String, List<dynamic>> map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MATERIAS DISPONIBLES',
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
                  0: FixedColumnWidth(50),  // Checkbox
                  1: FixedColumnWidth(80),  // Sigla
                  2: FixedColumnWidth(200), // Nombre
                  3: FixedColumnWidth(60),  // Grupo
                  4: FixedColumnWidth(150), // Docente
                  5: FixedColumnWidth(170), // Horario
                  6: FixedColumnWidth(60),  // Cupos
                },
                children: [
                  _buildTableHeader(['OK', 'SIGLA', 'NOMBRE', 'GRUPO', 'DOCENTE', 'HORARIO', 'CUPO']),
                  ...codes.expand((code) {
                    final grupos = map[code]!;
                    final isMateriaSelected = selectedSubjectCodes.contains(code);
                    final selectedGroupId = isMateriaSelected && selectedGroupsPerSubject[code] != null
                        ? selectedGroupsPerSubject[code]!['id'] 
                        : null;

                    return grupos.map((g) {
                      final hayCupo = (g['cuposDisponibles'] ?? 0) > 0;
                      final isSelected = isMateriaSelected && selectedGroupId == g['id'];
                      final isOtherGroupSelected = isMateriaSelected && selectedGroupId != g['id'];

                      return TableRow(
                        decoration: BoxDecoration(
                          color: isOtherGroupSelected 
                              ? Colors.grey.shade100 // Otro grupo de esta misma materia ya está elegido
                              : !hayCupo
                                  ? Colors.grey.shade100
                                  : isSelected
                                      ? UAGRMTheme.primaryBlue.withValues(alpha: 0.05)
                                      : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        children: [
                          TableCell(
                            child: !hayCupo
                                ? Tooltip(
                                    message: 'Cupos llenos',
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
                                    ),
                                  )
                                : isOtherGroupSelected
                                    ? Tooltip(
                                        message: 'Ya seleccionaste otro grupo de esta materia',
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Icon(Icons.do_not_disturb_on_outlined, size: 18, color: Colors.grey.shade400),
                                        ),
                                      )
                                    : Checkbox(
                                        value: isSelected,
                                        activeColor: UAGRMTheme.primaryBlue,
                                        onChanged: (val) {
                                          if (val == true) {
                                            // Verificar cupos (redundante pero seguro)
                                            if (!hayCupo) {
                                              _showTopSnackBar('El grupo ${g['grupo']} de ${g['materiaNombre']} está lleno.');
                                              return;
                                            }
                                            // Verificar choque de horario (excluyendo la materia actual si se está cambiando de grupo)
                                            final othersMap = Map<String, dynamic>.from(selectedGroupsPerSubject);
                                            othersMap.remove(code); // Si ya tenía un grupo, no choca consigo mismo
                                            
                                            final clashMsg = ScheduleValidator.checkClash(
                                              g['horario'] ?? '',
                                              g['materiaNombre'] ?? code,
                                              othersMap,
                                            );
                                            if (clashMsg != null) {
                                              _showTopSnackBar(clashMsg, color: Colors.orange.shade800);
                                              return; 
                                            }
                                            setState(() {
                                              selectedSubjectCodes.add(code);
                                              selectedGroupsPerSubject[code] = g;
                                            });
                                          } else {
                                            setState(() {
                                              selectedSubjectCodes.remove(code);
                                              selectedGroupsPerSubject.remove(code);
                                            });
                                          }
                                        },
                                      ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(code, style: TextStyle(fontSize: 12, color: (hayCupo && !isOtherGroupSelected) ? null : Colors.grey.shade500)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(g['materiaNombre'] ?? '', style: TextStyle(fontSize: 12, color: (hayCupo && !isOtherGroupSelected) ? null : Colors.grey.shade500)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(g['grupo'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (hayCupo && !isOtherGroupSelected) ? null : Colors.grey.shade500)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(g['docente'] ?? '', style: TextStyle(fontSize: 11, color: (hayCupo && !isOtherGroupSelected) ? null : Colors.grey.shade500)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(TimeFormatter.formatHorario(g['horario'] ?? ''), style: TextStyle(fontSize: 11, color: (hayCupo && !isOtherGroupSelected) ? null : Colors.grey.shade500)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${g['cuposDisponibles'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hayCupo 
                                      ? (isOtherGroupSelected ? Colors.grey.shade400 : UAGRMTheme.successGreen)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tabla de grupos confirmados — solo se muestra DESPUÉS de confirmar
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
                            child: Text(
                              TimeFormatter.formatHorario(g['horario'] ?? ''), 
                              style: const TextStyle(fontSize: 10)
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${g['cuposDisponibles'] ?? 0}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ((g['cuposDisponibles'] ?? 0) > 0)
                                    ? UAGRMTheme.successGreen
                                    : UAGRMTheme.errorRed,
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

  /// Banner de éxito tras confirmar
  Widget _buildConfirmationSuccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UAGRMTheme.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UAGRMTheme.successGreen),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: UAGRMTheme.successGreen, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Inscripción Confirmada!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UAGRMTheme.successGreen,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${selectedSubjectCodes.length} materia(s) inscrita(s) correctamente.',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Botón para reiniciar y hacer una nueva selección
  Widget _buildResetButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _confirmed = false;
            selectedSubjectCodes.clear();
            selectedGroupsPerSubject.clear();
          });
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Nueva Selección'),
      ),
    );
  }

  TableRow _buildTableHeader(List<String> labels) {
    return TableRow(
      decoration: const BoxDecoration(color: UAGRMTheme.primaryBlue),
      children: labels
          .map((l) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
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
