import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/career.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

class PreEnrollmentScreen extends StatefulWidget {
  const PreEnrollmentScreen({super.key});

  @override
  State<PreEnrollmentScreen> createState() => _PreEnrollmentScreenState();
}

class _PreEnrollmentScreenState extends State<PreEnrollmentScreen> {
  String? _selectedProceso = 'Inscripción';
  String? _selectedPeriodo; // código del periodo seleccionado

  // Query para obtener los períodos académicos activos del backend
  final String getPeriodsQuery = """
    query GetPeriodos {
      todosPeriodos {
        codigo
        nombre
        inscripcionesHabilitadas
      }
    }
  """;

  // Query para validar si el período actual está habilitado 
  final String getPanelQuery = """
    query GetPanel(\$registro: String!, \$codigoCarrera: String) {
      panelEstudiante(registro: \$registro, codigoCarrera: \$codigoCarrera) {
        periodoActual {
          codigo
          nombre
          inscripcionesHabilitadas
        }
        semestreActual
      }
    }
  """;

  // Query para obtener las carreras del estudiante
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final isLarge = Responsive.isTabletOrDesktop(context);
    final codigoCarrera = provider.selectedCareer?.code;

    if (codigoCarrera == null || codigoCarrera.isEmpty) {
      return MainLayout(
        title: 'Registrar Materias',
        subtitle: 'Selecciona tu carrera para continuar',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: _buildCareerSelector(context, provider.studentRegister ?? ''),
          ),
        ),
      );
    }

    return MainLayout(
      title: 'Registrar Materias',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isLarge ? 32 : 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: const Text(
                      'Seleccionar Proceso y Período',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UAGRMTheme.textDark),
                    ),
                  ),

                  // Contenido interactivo
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Query(
                      options: QueryOptions(
                        document: gql(getPanelQuery),
                        variables: {
                          'registro': provider.studentRegister ?? '',
                          'codigoCarrera': provider.selectedCareer?.code,
                        },
                        fetchPolicy: FetchPolicy.networkOnly,
                      ),
                      builder: (QueryResult panelResult,
                          {VoidCallback? refetch, FetchMore? fetchMore}) {
                        if (panelResult.isLoading) {
                          return const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator()));
                        }

                        final data =
                            panelResult.data?['panelEstudiante'];
                        final bool habilitado =
                            data?['periodoActual']
                                    ?['inscripcionesHabilitadas'] ??
                                false;
                        final String? codigoPeriodoActual =
                            data?['periodoActual']?['codigo']?.toString();

                        if (!habilitado) {
                          return _buildWarning(
                            'Periodo Cerrado',
                            'Actualmente no hay inscripciones habilitadas para tu carrera.',
                            Icons.lock_clock,
                            Colors.orange,
                          );
                        }

                        // Inicializar período seleccionado con el periodo actual del panel
                        if (_selectedPeriodo == null &&
                            codigoPeriodoActual != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() =>
                                  _selectedPeriodo = codigoPeriodoActual);
                            }
                          });
                        }

                        return _buildFormWithPeriods(context, codigoPeriodoActual);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget para seleccionar carrera cuando no hay una activa
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: UAGRMTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.school_outlined, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seleccionar Carrera', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Elige la carrera para inscribir materias', style: TextStyle(fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Builder(builder: (ctx) {
                if (result.isLoading) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                }
                if (result.hasException) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Error al cargar carreras', style: TextStyle(color: Colors.red.shade800))),
                        TextButton(onPressed: refetch, child: const Text('Reintentar')),
                      ],
                    ),
                  );
                }
                final carrerasData = result.data?['misCarreras'] as List<dynamic>? ?? [];
                if (carrerasData.isEmpty) {
                  return const Center(child: Text('No tienes carreras registradas.'));
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
                          border: Border.all(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.book_outlined, color: UAGRMTheme.primaryBlue, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: UAGRMTheme.textDark)),
                                  const SizedBox(height: 2),
                                  Text(facultad, style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: UAGRMTheme.primaryBlue),
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

  Widget _buildFormWithPeriods(BuildContext context, String? codigoPeriodoActual) {
    return Query(
      options: QueryOptions(
        document: gql(getPeriodsQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult periodsResult,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        // Obtener todos los periodos del backend
        final rawPeriods = periodsResult.data?['todosPeriodos'] as List<dynamic>? ?? [];

        // Si no hay periodos del backend o está cargando, usar solo el periodo actual
        List<Map<String, dynamic>> periods = rawPeriods
            .map((p) => {
                  'codigo': p['codigo']?.toString() ?? '',
                  'nombre': p['nombre']?.toString() ?? '',
                  'habilitado': p['inscripcionesHabilitadas'] ?? false,
                })
            .where((p) => p['codigo'].toString().isNotEmpty)
            .toList();

        // Si no hay datos del backend, usar el período actual como fallback
        if (periods.isEmpty && codigoPeriodoActual != null) {
          periods = [
            {
              'codigo': codigoPeriodoActual,
              'nombre': codigoPeriodoActual,
              'habilitado': true,
            }
          ];
        }

        // Verificar que el período seleccionado existe en la lista
        if (_selectedPeriodo != null &&
            periods.isNotEmpty &&
            !periods.any((p) => p['codigo'] == _selectedPeriodo)) {
          // El período seleccionado no está en la lista: resetear
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedPeriodo =
                  periods.isNotEmpty ? periods.first['codigo'] as String : null);
            }
          });
        }

        // Si aún no hay período seleccionado y hay períodos disponibles
        if (_selectedPeriodo == null && periods.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedPeriodo = periods.first['codigo'] as String);
            }
          });
        }

        return _buildForm(context, periods);
      },
    );
  }

  Widget _buildForm(
      BuildContext context, List<Map<String, dynamic>> periods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown de Proceso
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proceso',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: UAGRMTheme.textDark)),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProceso,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: UAGRMTheme.textGrey),
                  items: ['Inscripción', 'Adición', 'Retiro']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProceso = val;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Dropdown de Período Académico
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Período Académico',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: UAGRMTheme.primaryBlue)),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: periods.isEmpty
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.keyboard_arrow_down, color: UAGRMTheme.textGrey),
                              // Solo asignar value si existe en la lista
                              value: (_selectedPeriodo != null && periods.any((p) => p['codigo'] == _selectedPeriodo))
                                  ? _selectedPeriodo
                                  : null,
                              hint: const Text('Seleccionar período', style: TextStyle(color: UAGRMTheme.textGrey, fontSize: 13)),
                              
                              // selectedItemBuilder para mostrar el texto normal cuando está cerrado el dropdown
                              selectedItemBuilder: (BuildContext context) {
                                return periods.map((p) {
                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      p['nombre'] as String,
                                      style: const TextStyle(fontSize: 14, color: UAGRMTheme.textDark),
                                    ),
                                  );
                                }).toList();
                              },

                              // Generar items con el diseño rojo para la selección activa
                              items: periods.map((p) {
                                final isSelected = _selectedPeriodo == p['codigo'];
                                return DropdownMenuItem<String>(
                                  value: p['codigo'] as String,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? UAGRMTheme.primaryRed : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        if (isSelected) const Icon(Icons.check, color: Colors.white, size: 16),
                                        if (isSelected) const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            p['nombre'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              color: isSelected ? Colors.white : UAGRMTheme.textDark,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPeriodo = val;
                                });
                              },
                            ),
                          ),
                  ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (_selectedProceso != null && _selectedPeriodo != null)
              ? () => Navigator.pushNamed(context, '/enrollment', arguments: {
                    'proceso': _selectedProceso,
                    'periodo': _selectedPeriodo,
                  })
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: UAGRMTheme.sidebarDeep,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.blueGrey.shade400,
            disabledForegroundColor: Colors.white70,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Continuar',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildWarning(
      String title, String desc, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.shade900)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        fontSize: 13, color: color.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
