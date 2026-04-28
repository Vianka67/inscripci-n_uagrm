class Career {
  final String code;
  final String name;
  final String faculty;
  final int durationSemesters;
  final String planCode;

  Career({
    required this.code,
    required this.name,
    required this.faculty,
    required this.durationSemesters,
    this.planCode = '2020',
  });

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      code: json['codigo'] ?? '',
      name: json['nombre'] ?? '',
      faculty: json['facultad'] ?? '',
      durationSemesters: json['duracionSemestres'] ?? 9,
      planCode: json['planCode'] ?? '2020',
    );
  }
}
