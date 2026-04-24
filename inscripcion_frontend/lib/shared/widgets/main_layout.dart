import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/theme_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/career.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final Widget? bottomNavigationBar;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = Responsive.isTabletOrDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: isLarge
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                  ],
                ],
              ),
              centerTitle: false,
              backgroundColor: UAGRMTheme.sidebarDeep,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                Consumer<ThemeProvider>(
                  builder: (_, tp, __) => IconButton(
                    icon: Icon(
                      tp.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => tp.toggle(),
                    tooltip: 'Cambiar tema',
                  ),
                ),
              ],
            ),
      drawer: isLarge ? null : _buildSidebar(context),
      bottomNavigationBar: bottomNavigationBar,
      body: isLarge
          ? Row(
              children: [
                _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(context),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFFF8FAFC), // Fondo de superficie principal
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : child,
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: UAGRMTheme.sidebarDeep, 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.2),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
            ],
          ),
          Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (_, tp, __) => IconButton(
                  icon: Icon(tp.isDark ? Icons.light_mode : Icons.dark_mode, color: UAGRMTheme.textGrey),
                  onPressed: () => tp.toggle(),
                  tooltip: 'Cambiar tema',
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text('SIS - Origen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UAGRMTheme.textDark)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final isLarge = Responsive.isTabletOrDesktop(context);

    final sidebarContent = Container(
      width: 280,
      color: UAGRMTheme.sidebarBg, // Fondo del Sidebar institucional
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: UAGRMTheme.sidebarPanel)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo_uagrm.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AppInscripción', style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      Text('UAGRM', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARRERA', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  _SidebarCareerSelector(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SidebarItem(
                    icon: Icons.book_outlined,
                    title: 'Registrador de Materias',
                    route: '/pre-enrollment',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                    isEnabled: provider.selectedCareer != null,
                  ),
                  _SidebarItem(
                    icon: Icons.checklist_rtl_outlined,
                    title: 'Materias Habilitadas',
                    route: '/enabled-subjects',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                    isEnabled: provider.selectedCareer != null,
                  ),
                  _SidebarItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Fecha/Hora Inscripción',
                    route: '/enrollment-dates',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                    isEnabled: provider.selectedCareer != null,
                  ),
                  _SidebarItem(
                    icon: Icons.description_outlined,
                    title: 'Boleta de Inscripción',
                    route: '/enrollment-slip',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                  ),
                  _SidebarItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Transacciones',
                    route: '/transactions',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                  ),
                  _SidebarItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Calendario Académico',
                    route: '/calendar',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                  ),
                  _SidebarItem(
                    icon: Icons.grid_view_outlined,
                    title: 'Maestro de Ofertas',
                    route: '/maestro',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                    isEnabled: provider.selectedCareer != null,
                  ),
                  _SidebarItem(
                    icon: Icons.credit_card_outlined,
                    title: 'Pagos',
                    route: '/payments',
                    currentRoute: ModalRoute.of(context)?.settings.name,
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: UAGRMTheme.sidebarPanel)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: UAGRMTheme.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(_getInitials(provider.studentName ?? ''), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getShortName(provider.studentName ?? ''), style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Reg: ${provider.studentRegister ?? "N/A"}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      provider.setStudentRegister('');
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.6), size: 16),
                        const SizedBox(width: 8),
                        Text('Cerrar Sesión', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isLarge) return sidebarContent;
    
    return Drawer(
      child: sidebarContent,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    
    // Lógica para extraer iniciales: Primer Nombre + Primer Apellido
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _getShortName(String name) {
    if (name.isEmpty) return 'Estudiante UAGRM';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0];
    
    // Lógica para nombre corto: Primer Nombre + Primer Apellido
    return "${parts[0]} ${parts[1]}";
  }
}

class _SidebarCareerSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final selected = provider.selectedCareer;

    final String query = """
      query GetCarreras(\$registro: String!) {
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

    return Query(
      options: QueryOptions(
        document: gql(query),
        variables: {'registro': provider.studentRegister ?? ''},
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading && result.data == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final List carrerasData = result.data?['misCarreras'] ?? [];
        if (carrerasData.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: UAGRMTheme.sidebarPanel, borderRadius: BorderRadius.circular(6)),
            child: const Text('Sin carreras', style: TextStyle(color: Colors.white)),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: UAGRMTheme.sidebarPanel, 
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: UAGRMTheme.sidebarHover), 
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: UAGRMTheme.sidebarPanel,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
              value: carrerasData.any((item) => item['carrera']['codigo'] == selected?.code) ? selected?.code : null,
              hint: const Text('Seleccionar carrera', style: TextStyle(color: Colors.white70, fontSize: 13)),
              items: carrerasData.map<DropdownMenuItem<String>>((item) {
                final career = Career.fromJson(item['carrera']);
                return DropdownMenuItem<String>(
                  value: career.code,
                  child: Text(
                    career.name,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newCode) {
                if (newCode != null) {
                  final newCareerData = carrerasData.firstWhere((c) => c['carrera']['codigo'] == newCode);
                  provider.selectCareer(Career.fromJson(newCareerData['carrera']));
                  Navigator.pushReplacementNamed(context, '/panel');
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String? currentRoute;
  final bool isEnabled;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = currentRoute == route;
    if (route == '/panel' && currentRoute == '/') isActive = true;

    final isMobile = Responsive.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? UAGRMTheme.sidebarActiveRed : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            if (!isEnabled) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Debe seleccionar una carrera para acceder a este módulo', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade800,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
            if (!isActive) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(6),
          hoverColor: UAGRMTheme.sidebarHover,
          child: Padding(
            padding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: isMobile ? 18 : 20,
                    color: isEnabled
                        ? (isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6))
                        : Colors.white.withValues(alpha: 0.2)),
                SizedBox(width: isMobile ? 10 : 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isEnabled
                          ? (isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9))
                          : Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.3,
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
}
