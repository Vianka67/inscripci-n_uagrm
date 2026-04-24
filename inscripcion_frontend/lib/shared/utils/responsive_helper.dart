import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivo para la app UAGRM.
///
/// Breakpoints (equivalente a Tailwind CSS mobile-first):
///   Celular (mobile-first): ancho < 600 px  → sin prefijo
///   Tablet  (md:):          600 px <=  ancho < 1024 px
///   Desktop (lg:):          ancho >= 1024 px
///
/// Patrón de visibilidad equivalente a Tailwind:
///   hidden lg:block  →  ResponsiveVisibility(showOnMobile: false)
///   block  lg:hidden →  ResponsiveVisibility(showOnDesktop: false)
class Responsive {
  static const double _tabletBreak = 600;
  static const double _desktopBreak = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _tabletBreak;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _tabletBreak && w < _desktopBreak;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreak;

  /// Retorna true para tablet y desktop.
  /// Se verifica la altura para distinguir tablets reales de teléfonos en modo horizontal.
  static bool isTabletOrDesktop(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= _tabletBreak && size.height >= 500;
  }

  /// Retorna un valor genérico según el tamaño de pantalla actual.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _desktopBreak) return desktop;
    if (w >= _tabletBreak) return tablet;
    return mobile;
  }

  /// Espaciado horizontal recomendado por dispositivo.
  static double horizontalPadding(BuildContext context) =>
      value(context, mobile: 12.0, tablet: 24.0, desktop: 40.0);

  /// Número de columnas sugerido para grids.
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  /// Ancho máximo de contenido para mantener legibilidad.
  static double maxContentWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 800.0, desktop: 1100.0);

  // ─── Tamaños adaptivos ───────────────────────────────────────────────────

  /// Padding interno de botones según dispositivo.
  static EdgeInsets buttonPadding(BuildContext context) => isMobile(context)
      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
      : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

  /// Tamaño de fuente de botones según dispositivo.
  static double buttonFontSize(BuildContext context) =>
      isMobile(context) ? 13.0 : 15.0;

  /// Padding de filas de tabla según dispositivo.
  static EdgeInsets tableRowPadding(BuildContext context) => isMobile(context)
      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
      : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

  /// Padding del header de tabla según dispositivo.
  static EdgeInsets tableHeaderPadding(BuildContext context) =>
      isMobile(context)
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  /// Tamaño de fuente general de tabla según dispositivo.
  static double tableFontSize(BuildContext context) =>
      isMobile(context) ? 11.0 : 13.0;

  /// Tamaño de fuente de encabezados de tabla según dispositivo.
  static double tableHeaderFontSize(BuildContext context) =>
      isMobile(context) ? 10.0 : 12.0;

  /// Espaciado de columnas en DataTable.
  static double dataTableColumnSpacing(BuildContext context) =>
      isMobile(context) ? 8.0 : 24.0;
}

// ─── Widgets de visibilidad responsiva ──────────────────────────────────────
// Equivalente al patrón Tailwind: hidden lg:block / block lg:hidden

/// Muestra [child] solo en móvil (equivale a `block lg:hidden`).
/// En tablet/desktop el widget no ocupa espacio en el árbol.
class MobileOnly extends StatelessWidget {
  final Widget child;
  const MobileOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Responsive.isMobile(context) ? child : const SizedBox.shrink();
  }
}

/// Muestra [child] solo en tablet/desktop (equivale a `hidden lg:block`).
/// En móvil el widget no ocupa espacio en el árbol.
class DesktopOnly extends StatelessWidget {
  final Widget child;
  const DesktopOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Responsive.isTabletOrDesktop(context) ? child : const SizedBox.shrink();
  }
}

/// Selector responsivo: muestra [mobile] en móvil y [desktop] en tablet/desktop.
/// Útil para reemplazar duplicación de componentes con lógica condicional explícita.
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return Responsive.isTabletOrDesktop(context) ? desktop : mobile;
  }
}
