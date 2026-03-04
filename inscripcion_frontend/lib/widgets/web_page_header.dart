import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/utils/responsive_helper.dart';

/// Header de página con fondo azul, título y subtítulo en blanco.
/// Se muestra en tablet y desktop. En móvil devuelve vacío (se usa el AppBar nativo).
class WebPageHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget>? actions;

  const WebPageHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return const SizedBox.shrink();

    final isTablet = Responsive.isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 24,
        vertical: isTablet ? 14 : 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Ícono con fondo blanco semitransparente
          Container(
            width: isTablet ? 32 : 38,
            height: isTablet ? 32 : 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 17 : 20),
          ),
          const SizedBox(width: 14),

          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Breadcrumb (solo en desktop)
                if (!isTablet)
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Panel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ),
                      Text(
                        ' › $title',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                if (!isTablet) const SizedBox(height: 3),
                // Título principal
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Subtítulo
                if (subtitle != null && !isTablet) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Acciones opcionales
          if (actions != null) ...actions!,

          // Botón volver
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 14, color: Colors.white),
            label: Text(
              isTablet ? 'Volver' : 'Volver',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white60),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 10 : 12,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenedor de contenido centrado con fondo gris y max-width.
/// Se aplica en tablet y desktop. En móvil es transparente.
class WebContentArea extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const WebContentArea({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return child;
    return Expanded(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
