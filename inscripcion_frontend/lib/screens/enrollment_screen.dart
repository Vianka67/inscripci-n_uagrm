import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/utils/time_formatter.dart';

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
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
            color: current == 'TODOS' ? Colors.white : UAGRMTheme.primaryBlue.withOpacity(0.1),
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

  /// Encabezado "Seleccionar Todas las Materias" — ahora con lógica real
  Widget _buildSelectAllHeader(List<String> distinctSubjects, Map<String, List<dynamic>> subjectsMap) {
    final allSelected = distinctSubjects.isNotEmpty &&
        distinctSubjects.every((code) => selectedSubjectCodes.contains(code));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Seleccione Todas las Materias',
            style: TextStyle(fontWeight: FontWeight.bold, color: UAGRMTheme.textDark),
          ),
          Checkbox(
            value: allSelected,
            activeColor: UAGRMTheme.primaryBlue,
            onChanged: distinctSubjects.isEmpty
                ? null
                : (val) {
                    setState(() {
                      if (val == true) {
                        // Seleccionar todas: agregar cada materia con su primer grupo
                        for (final code in distinctSubjects) {
                          selectedSubjectCodes.add(code);
                          if (subjectsMap[code]!.isNotEmpty) {
                            selectedGroupsPerSubject[code] = subjectsMap[code]![0];
                          }
                        }
                      } else {
                        // Deseleccionar todas
                        selectedSubjectCodes.clear();
                        selectedGroupsPerSubject.clear();
                      }
                    });
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
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          columnWidths: const {
            0: FixedColumnWidth(50),
            1: FixedColumnWidth(80),
            2: FlexColumnWidth(),
          },
          children: [
            _buildTableHeader(['OK', 'SIGLA', 'NOMBRE']),
            ...codes.map((code) {
              final name = map[code]![0]['materiaNombre'];
              final isSelected = selectedSubjectCodes.contains(code);
              return TableRow(
                decoration: BoxDecoration(
                  color: isSelected ? UAGRMTheme.primaryBlue.withOpacity(0.05) : null,
                ),
                children: [
                  TableCell(
                    child: Checkbox(
                      value: isSelected,
                      activeColor: UAGRMTheme.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedSubjectCodes.add(code);
                            // Auto-seleccionar el primer grupo disponible
                            if (map[code]!.isNotEmpty) {
                              selectedGroupsPerSubject[code] = map[code]![0];
                            }
                          } else {
                            selectedSubjectCodes.remove(code);
                            selectedGroupsPerSubject.remove(code);
                          }
                        });
                      },
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(code, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(name, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              );
            }),
          ],
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
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
      ],
    );
  }

  /// Banner de éxito tras confirmar
  Widget _buildConfirmationSuccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UAGRMTheme.successGreen.withOpacity(0.1),
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
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: labels
          .map((l) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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
