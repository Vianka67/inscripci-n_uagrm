import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivo para la app UAGRM.
///
/// Breakpoints:
///   Mobile  : ancho < 600 px
///   Tablet  : 600 px â‰¤ ancho < 1024 px
///   Desktop : ancho â‰¥ 1024 px
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

  /// true para tablet Y desktop (úsalo donde cualquier pantalla grande funciona)
  /// En landscape mobile, el ancho puede superar 600px pero la altura es pequeña,
  /// por lo que verificamos ambas dimensiones para distinguir tablet real de phone landscape.
  static bool isTabletOrDesktop(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= _tabletBreak && size.height >= 500;
  }

  /// Devuelve [mobile], [tablet] o [desktop] según el ancho de pantalla.
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

  /// Padding horizontal recomendado según el tamaño de pantalla.
  static double horizontalPadding(BuildContext context) =>
      value(context, mobile: 16.0, tablet: 32.0, desktop: 48.0);

  /// Número de columnas para un grid según el tamaño de pantalla.
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  /// Ancho máximo del contenido principal.
  static double maxContentWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 800.0, desktop: 1100.0);
}
