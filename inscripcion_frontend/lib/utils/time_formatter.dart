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
