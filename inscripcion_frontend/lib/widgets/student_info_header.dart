import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/models/student.dart';
import 'package:inscripcion_frontend/utils/responsive_helper.dart';

class StudentInfoHeader extends StatelessWidget {
  final Student student;

  const StudentInfoHeader({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) return _buildMobileHeader();
    if (Responsive.isTablet(context)) return _buildTabletHeader();
    return _buildDesktopHeader();
  }

  // ─── HEADER DESKTOP: barra horizontal completa ────────────────────────────────

  Widget _buildDesktopHeader() {
    final isBlocked = student.status == 'BLOQUEADO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: UAGRMTheme.primaryBlue,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Text(
              student.fullName.isNotEmpty
                  ? student.fullName.substring(0, 2).toUpperCase()
                  : 'UA',
              style: const TextStyle(
                color: UAGRMTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nombre y registro
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                student.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Reg: ${student.register}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),

          const Spacer(),

          // Chips de información
          _WebInfoChip(icon: Icons.school_outlined, label: student.career),
          const SizedBox(width: 8),
          _WebInfoChip(icon: Icons.format_list_numbered, label: 'Sem. ${student.semester}'),
          const SizedBox(width: 8),
          _WebInfoChip(icon: Icons.class_outlined, label: student.modality),
          const SizedBox(width: 8),

          // Badge de estado
          _StatusBadge(isBlocked: isBlocked, status: student.status),
        ],
      ),
    );
  }

  // ─── HEADER TABLET: barra horizontal compacta (sin chips, solo nombre y estado) ─

  Widget _buildTabletHeader() {
    final isBlocked = student.status == 'BLOQUEADO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: UAGRMTheme.primaryBlue,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Text(
              student.fullName.isNotEmpty
                  ? student.fullName.substring(0, 2).toUpperCase()
                  : 'UA',
              style: const TextStyle(
                color: UAGRMTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nombre y registro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Reg: ${student.register} · ${student.career}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Semestre y modalidad como chips pequeños
          _WebInfoChip(icon: Icons.format_list_numbered, label: 'Sem. ${student.semester}'),
          const SizedBox(width: 6),

          // Badge de estado
          _StatusBadge(isBlocked: isBlocked, status: student.status),
        ],
      ),
    );
  }

  // ─── HEADER MÓVIL: diseño original ───────────────────────────────────────────

  Widget _buildMobileHeader() {
    final isBlocked = student.status == 'BLOQUEADO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: const BoxDecoration(
        color: UAGRMTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName.substring(0, 2).toUpperCase()
                      : 'UA',
                  style: const TextStyle(
                    color: UAGRMTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Reg: ${student.register}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _InfoMiniCard(icon: Icons.school, label: 'Carrera', value: student.career),
                    const SizedBox(height: 8),
                    _InfoMiniCard(icon: Icons.calendar_today, label: 'Semestre', value: student.semester),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _InfoMiniCard(icon: Icons.class_, label: 'Modalidad', value: student.modality),
                    const SizedBox(height: 8),
                    _InfoMiniCard(
                      icon: isBlocked ? Icons.lock : Icons.check_circle,
                      label: 'Estado',
                      value: student.status,
                      valueColor: isBlocked ? UAGRMTheme.errorRed : UAGRMTheme.successGreen,
                      isBadge: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Badge de estado (compartido entre desktop y tablet) ──────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isBlocked;
  final String status;
  const _StatusBadge({required this.isBlocked, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBlocked ? UAGRMTheme.errorRed : UAGRMTheme.successGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBlocked ? Icons.lock_outlined : Icons.check_circle_outline,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chip de info para tablet/desktop ────────────────────────────────────────

class _WebInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WebInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Mini card para móvil (original) ─────────────────────────────────────────

class _InfoMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBadge;

  const _InfoMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                if (isBadge)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: valueColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
