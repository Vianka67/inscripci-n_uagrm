class Student {
  final String register;
  final String fullName;
  final String career;
  final String semester;
  final String modality;
  final String status; // ACTIVO, BLOQUEADO

  Student({
    required this.register,
    required this.fullName,
    required this.career,
    required this.semester,
    required this.modality,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      register: json['estudiante']?['registro']?.toString() ?? '',
      fullName: json['estudiante']?['nombreCompleto'] ?? '',
      career: json['carrera']?['nombre'] ?? '',
      semester: json['semestreActual']?.toString() ?? '',
      modality: json['modalidad'] ?? '',
      status: json['estado'] ?? 'ACTIVO',
    );
  }
}

class PanelOptions {
  final bool inscriptionDates;
  final bool blocked;
  final bool enabledSubjects;
  final bool enabledPeriod;
  final bool enrollmentSlips;
  final bool enrollment;

  PanelOptions({
    this.inscriptionDates = false,
    this.blocked = false,
    this.enabledSubjects = false,
    this.enabledPeriod = false,
    this.enrollmentSlips = false,
    this.enrollment = false,
  });

  factory PanelOptions.fromJson(Map<String, dynamic> json, Map<String, dynamic>? periodJson) {
    return PanelOptions(
      inscriptionDates: json['fechasInscripcion'] ?? false,
      blocked: json['bloqueo'] ?? false,
      enabledSubjects: true, // Defaulting to true as it's not in options
      enabledPeriod: periodJson?['inscripcionesHabilitadas'] ?? false,
      enrollmentSlips: json['boleta'] ?? false,
      enrollment: json['inscripcion'] ?? false,
    );
  }
}
