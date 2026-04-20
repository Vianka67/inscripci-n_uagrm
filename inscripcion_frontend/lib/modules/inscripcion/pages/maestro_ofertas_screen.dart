import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';

class MaestroOfertasScreen extends StatefulWidget {
  const MaestroOfertasScreen({super.key});

  @override
  State<MaestroOfertasScreen> createState() => _MaestroOfertasScreenState();
}

class _MaestroOfertasScreenState extends State<MaestroOfertasScreen> {
  String _searchQuery = '';
  int? _selectedLevel; // null means 'Todos los niveles'

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

  final String getOfertasMasterQuery = """
    query GetOfertasMaster(\$codigoCarrera: String) {
      ofertasMateria(codigoCarrera: \$codigoCarrera) {
        materiaCodigo
        materiaNombre
        semestre
        grupo
        horario
        docente
        cuposDisponibles
        cupoActual
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final codigoCarrera = provider.selectedCareer?.code;
    final carreraNombre = provider.selectedCareer?.name ?? 'Carrera no seleccionada';

    return MainLayout(
      title: 'Maestro de Ofertas',
      subtitle: 'Consulta de todas las materias ofertadas por la carrera',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título y filtros unificados en una tarjeta blanca
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera superior
                      Row(
                        children: [
                          const Icon(Icons.grid_view_outlined, color: UAGRMTheme.sidebarBg, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Maestro de Ofertas - $carreraNombre',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: UAGRMTheme.sidebarBg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Barra de filtros
                      _buildFiltersBar(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tabla de resultados
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Query(
                      options: QueryOptions(
                        document: gql(getOfertasMasterQuery),
                        variables: {'codigoCarrera': codigoCarrera},
                        fetchPolicy: FetchPolicy.networkOnly,
                      ),
                      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
                        if (result.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (result.hasException) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                                const SizedBox(height: 16),
                                const Text('Error al cargar ofertas', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(result.exception.toString(), textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
                              ],
                            ),
                          );
                        }

                        final dataList = result.data?['ofertasMateria'] as List<dynamic>? ?? [];

                        // Aplicar filtros locales (Búsqueda por nombre/sigla y Nivel)
                        final filteredList = dataList.where((item) {
                          final nombre = (item['materiaNombre'] ?? '').toString().toLowerCase();
                          final sigla = (item['materiaCodigo'] ?? '').toString().toLowerCase();
                          final matchesSearch = _searchQuery.isEmpty || 
                                              nombre.contains(_searchQuery.toLowerCase()) || 
                                              sigla.contains(_searchQuery.toLowerCase());
                          
                          final level = item['semestre'] as int?;
                          final matchesLevel = _selectedLevel == null || level == _selectedLevel;

                          return matchesSearch && matchesLevel;
                        }).toList();

                        if (filteredList.isEmpty) {
                          return const Center(child: Text('No se encontraron materias ofertadas según los filtros.'));
                        }

                        return _buildCleanTable(filteredList);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por sigla o nombre...',
                hintStyle: TextStyle(color: UAGRMTheme.textGrey, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: UAGRMTheme.textGrey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedLevel,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down, color: UAGRMTheme.textGrey, size: 18),
              selectedItemBuilder: (BuildContext context) {
                return [null, ...List.generate(9, (index) => index + 1)].map((level) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      level == null ? 'Todos los niveles' : 'Nivel $level',
                      style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark),
                    ),
                  );
                }).toList();
              },
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedLevel == null ? const Color(0xFFF1F5F9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedLevel == null) const Icon(Icons.check, color: UAGRMTheme.textDark, size: 16),
                        if (_selectedLevel == null) const SizedBox(width: 4),
                        Text('Todos', style: TextStyle(fontSize: 13, color: _selectedLevel == null ? UAGRMTheme.textDark : UAGRMTheme.textGrey)),
                      ]
                    )
                  )
                ),
                ...List.generate(9, (index) => index + 1).map((level) => 
                  DropdownMenuItem<int?>(
                    value: level,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedLevel == level ? const Color(0xFFF1F5F9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedLevel == level) const Icon(Icons.check, color: UAGRMTheme.textDark, size: 16),
                          if (_selectedLevel == level) const SizedBox(width: 4),
                          Text('Nivel $level', style: TextStyle(fontSize: 13, color: _selectedLevel == level ? UAGRMTheme.textDark : UAGRMTheme.textGrey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedLevel = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanTable(List<dynamic> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth > 900 ? constraints.maxWidth : 900,
            child: StandardTableContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
        // Table Header
        AppTableHeader(
          children: const [
            SizedBox(width: 80,  child: AppHeaderCell('Sigla')),
            Expanded(flex: 3,   child: AppHeaderCell('Materia')),
            SizedBox(width: 50,  child: AppHeaderCell('Nivel')),
            SizedBox(width: 50,  child: AppHeaderCell('Grupo')),
            SizedBox(width: 110, child: AppHeaderCell('Turno')),
            Expanded(flex: 2,   child: AppHeaderCell('Docente')),
            Expanded(flex: 2,   child: AppHeaderCell('Horario')),
            SizedBox(width: 60,  child: AppHeaderCell('Cupos', textAlign: TextAlign.center)),
            SizedBox(width: 50,  child: AppHeaderCell('Inscr', textAlign: TextAlign.center)),
          ],
        ),
        // Cuerpo de la tabla con scroll vertical
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = items[index];
              final sigla = item['materiaCodigo']?.toString() ?? '';
              final nombre = item['materiaNombre']?.toString() ?? '';
              final semestre = item['semestre']?.toString() ?? '';
              final grupo = item['grupo']?.toString() ?? '';
              final horario = item['horario']?.toString() ?? '';
              
              String calcTurno(String? h) {
                if (h == null || h.isEmpty) return 'Mañana';
                final upper = h.toUpperCase();
                if (upper.contains('13:') || upper.contains('14:') || upper.contains('15:') || upper.contains('16:') || upper.contains('17:')) return 'Tarde';
                if (upper.contains('18:') || upper.contains('19:') || upper.contains('20:') || upper.contains('21:') || upper.contains('22:')) return 'Noche';
                return 'Mañana';
              }
              final turno = calcTurno(horario);

              final docente = item['docente']?.toString() ?? 'Lic. Por Asignar';
              final cuposDisp = item['cuposDisponibles'] as int? ?? 0;
              final cupoActual = item['cupoActual']?.toString() ?? '0';
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    SizedBox(width: 80,  child: Text(sigla, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: UAGRMTheme.textDark))),
                    Expanded(flex: 3,   child: Text(nombre, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark))),
                    SizedBox(width: 50,  child: Text(semestre, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey))),
                    SizedBox(width: 50,  child: Text(grupo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: UAGRMTheme.textDark))),
                    // Turno: usa AppTurnoBadge centralizado
                    SizedBox(width: 110, child: Align(alignment: Alignment.centerLeft, child: AppTurnoBadge(horario))),
                    Expanded(flex: 2,   child: Text(docente, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark))),
                    Expanded(flex: 2,   child: Text(horario, style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    // Cupos: usa AppCupoBadge centralizado
                    SizedBox(width: 60,  child: Center(child: AppCupoBadge(cuposDisp))),
                    SizedBox(width: 50,  child: Text(cupoActual, style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark), textAlign: TextAlign.center)),
                  ],
                ),
              );
            },
          ),
        ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

}

