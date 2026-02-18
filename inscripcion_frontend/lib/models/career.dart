class Career {
  final String code;
  final String name;
  final String faculty;
  final int durationSemesters;

  Career({
    required this.code,
    required this.name,
    required this.faculty,
    required this.durationSemesters,
  });

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      code: json['codigo'] ?? '',
      name: json['nombre'] ?? '',
      faculty: json['facultad'] ?? '',
      durationSemesters: json['duracionSemestres'] ?? 9, // Default 9 semestres
    );
  }
}
