/// Utility to detect schedule conflicts between enrolled subjects.
class ScheduleValidator {
  /// Returns a conflict message if [newHorario] clashes with any already
  /// selected subject in [selectedGroups], or null if there's no conflict.
  ///
  /// [newHorario] format example: "LUN 07:00-09:00, MIE 07:00-09:00"
  /// [newMateriaName] is only used to build the conflict message.
  /// [selectedGroups] maps materiaCodigo -> oferta map which must contain 'horario'.
  static String? checkClash(
    String newHorario,
    String newMateriaName,
    Map<String, dynamic> selectedGroups,
  ) {
    final newSlots = _parseHorario(newHorario);
    if (newSlots.isEmpty) return null; // No horario → no conflict

    for (final entry in selectedGroups.entries) {
      final existingHorario = entry.value['horario']?.toString() ?? '';
      final existingNombre =
          entry.value['materiaNombre']?.toString() ?? entry.key;
      final existingSlots = _parseHorario(existingHorario);

      for (final newSlot in newSlots) {
        for (final existSlot in existingSlots) {
          if (_overlaps(newSlot, existSlot)) {
            return 'Choque de horario con "$existingNombre"';
          }
        }
      }
    }
    return null;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  static List<_TimeSlot> _parseHorario(String horario) {
    final slots = <_TimeSlot>[];
    if (horario.trim().isEmpty) return slots;

    // Formatos esperados: "LUN 07:00-09:00", "L-07:00-09:00" o "LUN-07:00-09:00"
    final segments = horario.split(',');
    for (final seg in segments) {
      final part = seg.trim();
      if (part.isEmpty) continue;

      // Try pattern: "DAY HH:MM-HH:MM"
      final match = RegExp(
              r'([A-Za-záéíóúÁÉÍÓÚ]+)[\s\-]+(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})')
          .firstMatch(part);
      if (match != null) {
        final day = _normalizeDay(match.group(1)!);
        final start = _parseTime(match.group(2)!);
        final end = _parseTime(match.group(3)!);
        if (day != null && start != null && end != null) {
          slots.add(_TimeSlot(day, start, end));
        }
      }
    }
    return slots;
  }

  static String? _normalizeDay(String raw) {
    final d = raw.toUpperCase().trim();
    const map = {
      'L': 'LUN',
      'LU': 'LUN',
      'LUN': 'LUN',
      'LUNES': 'LUN',
      'M': 'MAR',
      'MA': 'MAR',
      'MAR': 'MAR',
      'MARTES': 'MAR',
      'MI': 'MIE',
      'MIE': 'MIE',
      'MIERCOLES': 'MIE',
      'MIÉRCOLES': 'MIE',
      'J': 'JUE',
      'JU': 'JUE',
      'JUE': 'JUE',
      'JUEVES': 'JUE',
      'V': 'VIE',
      'VI': 'VIE',
      'VIE': 'VIE',
      'VIERNES': 'VIE',
      'S': 'SAB',
      'SA': 'SAB',
      'SAB': 'SAB',
      'SABADO': 'SAB',
      'SÁBADO': 'SAB',
    };
    return map[d];
  }

  static int? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static bool _overlaps(_TimeSlot a, _TimeSlot b) {
    if (a.day != b.day) return false;
    // Overlap if one starts before the other ends
    return a.start < b.end && b.start < a.end;
  }
}

class _TimeSlot {
  final String day;
  final int start; // minutos desde la medianoche
  final int end;

  const _TimeSlot(this.day, this.start, this.end);
}
