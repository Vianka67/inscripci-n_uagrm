import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

// SISTEMA DE DISEÑO CENTRALIZADO (APP UI KIT)
// Se deben usar estos widgets en lugar de definir contenedores o badges ad-hoc
// para garantizar coherencia visual en todos los módulos.

// Colores del sistema de diseño
class AppColors {
  // Fondo y superficies
  static const Color pageBackground  = Color(0xFFF4F7FA);
  static const Color cardSurface     = Colors.white;
  static const Color tableDivider    = Color(0xFFF1F5F9);

  // Headers de tabla
  static const Color tableHeaderBg   = UAGRMTheme.sidebarDeep;

  // Turnos
  static const Color manhanaBg       = UAGRMTheme.sidebarBg;
  static const Color manhanaFg       = Colors.white;
  static const Color tardeBg         = Color(0xFFF1F5F9); 
  static const Color tardeFg         = Color(0xFF475569); 
  static const Color nocheBg         = Color(0xFFE2E8F0); 
  static const Color nocheFg         = Color(0xFF334155); 

  // Cupos
  static const Color cupoOkColor     = Color(0xFF388E3C); 
  static const Color sinCupoBg       = Color(0xFFFFEBEE); 
  static const Color sinCupoFg       = Color(0xFFD32F2F); 

  // Procesos de transacción
  static const Color inscripcionBg   = UAGRMTheme.sidebarBg;
  static const Color inscripcionFg   = Colors.white;
  static const Color adicionBg       = Color(0xFFF0FDF4);
  static const Color adicionFg       = Color(0xFF166534);
  static const Color retiroBg        = Color(0xFFFFF7ED);
  static const Color retiroFg        = Color(0xFF9A3412);
}

// Badge de turno unificado
class AppTurnoBadge extends StatelessWidget {
  final String horario;

  const AppTurnoBadge(this.horario, {super.key});

  /// Calcula turno a partir del texto del horario.
  static String calcTurno(String? horario) {
    if (horario == null || horario.isEmpty) return 'ND';
    final h = horario.toUpperCase();
    // Detectar tarde: horas 13-17
    if (h.contains('13:') || h.contains('14:') || h.contains('15:') ||
        h.contains('16:') || h.contains('17:') ||
        h.contains('1300') || h.contains('1400') || h.contains('1500') ||
        h.contains('1600') || h.contains('1700')) return 'Tarde';
    // Detectar noche: 18-22
    if (h.contains('18:') || h.contains('19:') || h.contains('20:') ||
        h.contains('21:') || h.contains('22:') ||
        h.contains('1800') || h.contains('1900') || h.contains('2000') ||
        h.contains('2100') || h.contains('2200')) return 'Noche';
    // Default: Mañana
    return 'Mañana';
  }

  @override
  Widget build(BuildContext context) {
    final turno = calcTurno(horario);
    if (turno == 'ND') return const SizedBox.shrink();

    Color bg;
    Color fg;
    if (turno == 'Tarde') {
      bg = AppColors.tardeBg;
      fg = AppColors.tardeFg;
    } else if (turno == 'Noche') {
      bg = AppColors.nocheBg;
      fg = AppColors.nocheFg;
    } else {
      bg = AppColors.manhanaBg;
      fg = AppColors.manhanaFg;
    }

    final isMobile = Responsive.isMobile(context);
    return Center(
      child: Container(
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 7, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(isMobile ? 10 : 14)),
        child: Text(
          turno.toUpperCase(),
          softWrap: false,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: fg,
            fontSize: isMobile ? 8.0 : 10.0,
            fontWeight: FontWeight.w600,
            letterSpacing: isMobile ? 0.3 : 0.5,
          ),
        ),
      ),
    );
  }
}

// Badge de cupos (número o "Sin cupo")
class AppCupoBadge extends StatelessWidget {
  final int cupos;

  const AppCupoBadge(this.cupos, {super.key});

  @override
  Widget build(BuildContext context) {
    final hasCupo = cupos > 0;
    final isMobile = Responsive.isMobile(context);
    final fontSize = isMobile ? 10.0 : 12.0;
    if (hasCupo) {
      return Text(
        '$cupos',
        style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.w600, color: AppColors.cupoOkColor,
        ),
        textAlign: TextAlign.center,
      );
    }
    return Center(
      child: Container(
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.sinCupoBg,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        ),
        child: Text(
          'SIN CUPO',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: AppColors.sinCupoFg,
            fontSize: isMobile ? 8.0 : 10.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// Badge de tipo de proceso (Inscripción/Adición/Retiro)
class AppProcessBadge extends StatelessWidget {
  final String proceso;

  const AppProcessBadge(this.proceso, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (proceso) {
      case 'Adición':
        bg = AppColors.adicionBg; fg = AppColors.adicionFg; break;
      case 'Retiro':
        bg = AppColors.retiroBg; fg = AppColors.retiroFg; break;
      default: // Inscripción
        bg = AppColors.inscripcionBg; fg = AppColors.inscripcionFg;
    }
    final isMobile = Responsive.isMobile(context);
    return Center(
      child: Container(
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 5, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(isMobile ? 10 : 14)),
        child: Text(
          proceso.toUpperCase(),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
              color: fg,
              fontSize: isMobile ? 8.0 : 10.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3),
        ),
      ),
    );
  }
}

// Contenedor de página con sombra y bordes redondeados
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Contenedor de tabla con recortes en los bordes para el header
class AppTableCard extends StatelessWidget {
  final Widget child;

  const AppTableCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

// Fila de encabezado con fondo institucional
class AppTableHeader extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppTableHeader({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? Responsive.tableHeaderPadding(context);
    return Container(
      padding: effectivePadding,
      color: AppColors.tableHeaderBg,
      child: Row(children: children),
    );
  }
}

// Celda de encabezado blanca con estilo resaltado
class AppHeaderCell extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const AppHeaderCell(this.text, {super.key, this.textAlign = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.tableHeaderFontSize(context);
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        letterSpacing: Responsive.isMobile(context) ? 0.3 : 0.5,
      ),
    );
  }
}

// Campo de búsqueda unificado
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AppSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: UAGRMTheme.textGrey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: UAGRMTheme.textGrey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// Título de sección con icono descriptivo
class AppPageTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const AppPageTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final iconSize = isMobile ? 18.0 : 22.0;
    final fontSize = isMobile ? 15.0 : 18.0;
    return Row(
      children: [
        Icon(icon, color: UAGRMTheme.sidebarBg, size: iconSize),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: UAGRMTheme.sidebarBg,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Badge de estado genérico
class AppEstadoBadge extends StatelessWidget {
  final String estado;
  /// Color personalizado. Si null, se infiere del texto.
  final Color? color;

  const AppEstadoBadge(this.estado, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    Color c = color ?? _infer();
    final isMobile = Responsive.isMobile(context);
    return Center(
      child: Container(
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 5, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Text(
          estado,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: c,
            fontSize: isMobile ? 8.0 : 10.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Color _infer() {
    switch (estado.toLowerCase()) {
      case 'inscrito':
      case 'confirmado':
      case 'activo':
        return UAGRMTheme.successGreen;
      case 'sin cupo':
      case 'bloqueado':
        return UAGRMTheme.errorRed;
      default:
        return UAGRMTheme.textGrey;
    }
  }
}
