class TimeFormatter {
  /// Convierte un horario de formato 24h a AM/PM
  /// Ejemplo: "Lun-Mie-Vie 07:00-09:00" -> "Lun-Mie-Vie 07:00 AM - 09:00 AM"
  /// Ejemplo: "Lun-Mie 14:00-16:00" -> "Lun-Mie 02:00 PM - 04:00 PM"
  static String formatHorario(String horario) {
    if (horario.isEmpty) return horario;

    // Regex para encontrar patrones de HH:mm
    final RegExp timeRegExp = RegExp(r'(\d{1,2}):(\d{2})');
    
    return horario.replaceAllMapped(timeRegExp, (match) {
      final int hour = int.tryParse(match.group(1) ?? '') ?? 0;
      final String minute = match.group(2) ?? '00';
      
      final String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;
      
      final String hourString = displayHour.toString().padLeft(2, '0');
      
      return '$hourString:$minute $period';
    }).replaceAll('-', ' - '); // Mejorar legibilidad del guión
  }
}

class ScheduleSlot {
  final int dayIndex; // 1 = Lunes, 6 = Sábado
  final int startMinutes; // Minutos desde las 00:00 (ej. 07:00 = 420)
  final int endMinutes; // Minutos desde las 00:00

  ScheduleSlot(this.dayIndex, this.startMinutes, this.endMinutes);

  bool overlapsWith(ScheduleSlot other) {
    if (dayIndex != other.dayIndex) return false;
    // Verifica si [start1, end1) choca con [start2, end2)
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }
}

class ScheduleValidator {
  static const _daysMap = {
    'Lu': 1, 'Lun': 1, 'Lunes': 1,
    'Ma': 2, 'Mar': 2, 'Martes': 2,
    'Mi': 3, 'Mie': 3, 'Miércoles': 3,
    'Ju': 4, 'Jue': 4, 'Jueves': 4,
    'Vi': 5, 'Vie': 5, 'Viernes': 5,
    'Sa': 6, 'Sab': 6, 'Sábado': 6,
    'Do': 7, 'Dom': 7, 'Domingo': 7,
  };

  /// Parsea un horario tipo "Lu-Mi-Vi 07:00-09:15" a intervalos numéricos manejables.
  static List<ScheduleSlot> parseScheduleString(String schedule) {
    final slots = <ScheduleSlot>[];
    if (schedule.isEmpty || schedule.toUpperCase() == 'POR DEFINIR') return slots;

    // A veces puede venir separado por punto y coma si hay más de un turno ej. "Lu 07:00-09:15; Mi 07:00-09:15"
    final parts = schedule.split(RegExp(r'[;,]'));

    for (var part in parts) {
      part = part.trim();
      if (part.isEmpty) continue;

      // Buscar las horas (ej. 07:00-09:15)
      final timeRegex = RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})');
      final timeMatch = timeRegex.firstMatch(part);
      if (timeMatch == null) continue;

      final startStr = timeMatch.group(1)!;
      final endStr = timeMatch.group(2)!;

      final startMinutes = _timeToMinutes(startStr);
      final endMinutes = _timeToMinutes(endStr);

      // Extraer los días quitando la parte de la hora
      final daysPart = part.substring(0, timeMatch.start).trim();
      final dayMatches = RegExp(r'[A-Za-záéíóú]+').allMatches(daysPart);

      for (var dMatch in dayMatches) {
        final dayStr = dMatch.group(0)!;
        final dayIndex = _getDayIndex(dayStr);
        if (dayIndex != null) {
          slots.add(ScheduleSlot(dayIndex, startMinutes, endMinutes));
        }
      }
    }

    return slots;
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  static int? _getDayIndex(String day) {
    // Normalizar a CamelCase o buscar prefijos comunes
    for (final entry in _daysMap.entries) {
      if (day.toLowerCase().startsWith(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  /// Revisa si `newSchedule` choca con una lista de `existingSchedules`.
  /// Retorna un mensaje de error con el cruce detectado, o `null` si todo está OK.
  static String? checkClash(String newSchedule, String newSubjectName, Map<String, dynamic> existingGroups) {
    final newSlots = parseScheduleString(newSchedule);
    if (newSlots.isEmpty) return null;

    for (final entry in existingGroups.entries) {
      final existingCode = entry.key;
      final existingData = entry.value;
      final existingSchedule = existingData['horario']?.toString() ?? '';
      final existingSubjectName = existingData['materiaNombre']?.toString() ?? existingCode;

      final existingSlots = parseScheduleString(existingSchedule);

      for (final nSlot in newSlots) {
        for (final eSlot in existingSlots) {
          if (nSlot.overlapsWith(eSlot)) {
            return 'La materia "$newSubjectName" choca en horario con "$existingSubjectName".';
          }
        }
      }
    }
    return null; // No hay choques
  }
}
