import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

/// Centra el contenido con un ancho máximo en tablet y desktop.
/// En móvil pasa el hijo tal cual.
class WebCenteredLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const WebCenteredLayout({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Fondo de página web con color gris claro (F4F6F9).
/// En móvil es transparente.
class WebPageBackground extends StatelessWidget {
  final Widget child;

  const WebPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return child;
    return Container(
      color: const Color(0xFFF4F6F9),
      child: child,
    );
  }
}
