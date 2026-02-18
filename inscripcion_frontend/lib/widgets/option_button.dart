import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';

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
    return Material(
      color: Colors.white,
      elevation: isAvailable ? 2 : 0,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isAvailable ? UAGRMTheme.primaryBlue.withOpacity(0.1) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isAvailable ? UAGRMTheme.primaryBlue : Colors.grey,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        isAvailable ? title : 'No disponible',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? UAGRMTheme.textDark : Colors.grey,
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
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: UAGRMTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: badgeText != null
                        ? Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
