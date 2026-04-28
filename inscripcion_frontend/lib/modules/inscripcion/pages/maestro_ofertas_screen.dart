import 'package:flutter/foundation.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
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
  int? _selectedLevel; // null = Todos los niveles

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
    query GetOfertasMaster(\$registro: Int!, \$carr: Int!, \$plan: String!, \$lugar: Int!, \$sem: String!, \$ano: Int!) {
      allMoferta(registro: \$registro, carr: \$carr, plan: \$plan, lugar: \$lugar, sem: \$sem, ano: \$ano) {
        materiaCodigo
        materiaNombre
        semestre
        grupo
        horario
        docente
        cuposDisponibles
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
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título y filtros unificados en una tarjeta blanca
                Container(
                  padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
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
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.grid_view_outlined, color: UAGRMTheme.sidebarBg, size: Responsive.isMobile(context) ? 20 : 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Maestro de Ofertas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobile(context) ? 15 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: UAGRMTheme.sidebarBg,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              carreraNombre,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: UAGRMTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
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
                        variables: {
                          'registro': int.tryParse(provider.studentRegister ?? '0') ?? 0,
                          'carr': int.tryParse(codigoCarrera ?? '0') ?? 0,
                          'plan': '1',
                          'lugar': 4271,
                          'sem': '1',
                          'ano': 2026
                        },
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

                        final dataList = result.data?['allMoferta'] as List<dynamic>? ?? [];

                        // Aplicar filtros locales (Búsqueda por nombre/sigla y Nivel)
                        final filteredList = dataList.where((item) {
                          final nombre = (item['materiaNombre'] ?? '').toString().toLowerCase();
                          final sigla = (item['materiaCodigo'] ?? '').toString().toLowerCase();
                          final matchesSearch = _searchQuery.isEmpty || 
                                              nombre.contains(_searchQuery.toLowerCase()) || 
                                              sigla.contains(_searchQuery.toLowerCase());
                          
                          final level = item['semestre'] as int?;
                          final matchesLevel = _selectedLevel == null || level == _selectedLevel; // Filtrado por nivel

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
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por sigla o nombre...',
                hintStyle: TextStyle(color: UAGRMTheme.textGrey, fontSize: 12),
                prefixIcon: Icon(Icons.search, color: UAGRMTheme.textGrey, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedLevel,
                isExpanded: true,
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
    final isMobile = Responsive.isMobile(context);
    
    final labels = isMobile 
        ? const ['Sigla', 'Materia', 'Grp.', 'Cupo']
        : const ['Sigla', 'Materia', 'Nivel', 'Grupo', 'Turno', 'Docente', 'Horario', 'Cupos', 'Inscr'];
    
    final flexValues = isMobile
        ? [2, 5, 2, 2]
        : [1, 3, 1, 1, 2, 2, 2, 1, 1];

    return StandardTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardFlexHeader(
            labels: labels,
            flexValues: flexValues,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final sigla = item['materiaCodigo']?.toString() ?? '';
                final nombre = item['materiaNombre']?.toString() ?? '';
                final semestre = item['semestre']?.toString() ?? '';
                final grupo = item['grupo']?.toString() ?? '';
                final horario = item['horario']?.toString() ?? '';
                final docente = item['docente']?.toString() ?? 'Lic. Por Asignar';
                final cuposDisp = item['cuposDisponibles'] as int? ?? 0;
                final cupoActual = item['cupoActual']?.toString() ?? '0';

                return StandardFlexRow(
                  flexValues: flexValues,
                  isLast: index == items.length - 1,
                  cells: [
                    tableText(sigla, isMobile, bold: true),
                    tableText(nombre, isMobile, bold: true),
                    if (!isMobile)
                      tableText(semestre, isMobile),
                    tableText(grupo, isMobile, bold: true),
                    if (!isMobile)
                      Align(alignment: Alignment.centerLeft, child: AppTurnoBadge(horario)),
                    if (!isMobile)
                      tableText(docente, isMobile),
                    if (!isMobile)
                      tableText(horario, isMobile, color: UAGRMTheme.textGrey),
                    Center(child: AppCupoBadge(cuposDisp)),
                    if (!isMobile)
                      tableText(cupoActual, isMobile),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

