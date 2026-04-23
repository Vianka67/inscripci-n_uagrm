import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivo para la app UAGRM.
/// 
/// Breakpoints:
///   Celular: ancho < 600 px
///   Tablet:  600 px <= ancho < 1024 px
///   Desktop: ancho >= 1024 px
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
      value(context, mobile: 16.0, tablet: 32.0, desktop: 48.0);

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
}
