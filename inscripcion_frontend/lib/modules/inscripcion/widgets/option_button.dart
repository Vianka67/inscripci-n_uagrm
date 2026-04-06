import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

class OptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isAvailable;
  final bool hasBadge;
  final String? badgeText;
  final VoidCallback? onTap;

  const OptionButton({
    super.key,
    required this.icon,
    required this.title,
    this.isAvailable = true,
    this.hasBadge = false,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = Responsive.isTabletOrDesktop(context);
    final iconSize = 28.0;
    final containerSize = isLarge ? 44.0 : 56.0;
    final fontSize = isLarge ? 12.0 : 13.0;
    final radius = isLarge ? 8.0 : 12.0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: isAvailable ? (isLarge ? 1 : 2) : 0,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        hoverColor: isLarge ? UAGRMTheme.primaryBlue.withValues(alpha: 0.04) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isAvailable
                  ? (isLarge ? Colors.grey.shade200 : Colors.transparent)
                  : Colors.grey.shade300,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: containerSize,
                      height: containerSize,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? UAGRMTheme.primaryBlue.withValues(alpha: isLarge ? 0.08 : 0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isAvailable ? UAGRMTheme.primaryBlue : Colors.grey,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(height: isLarge ? 8 : 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isLarge ? 6 : 8),
                      child: Text(
                        isAvailable ? title : 'No disponible',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasBadge && isAvailable)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: UAGRMTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeText ?? '!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
