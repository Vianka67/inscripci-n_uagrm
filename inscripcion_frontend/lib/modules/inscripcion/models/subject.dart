class Subject {
  final String code;
  final String name;
  final int credits;
  final int semester;
  final bool isRequired;
  final bool isEnabled;

  Subject({
    required this.code,
    required this.name,
    required this.credits,
    required this.semester,
    required this.isRequired,
    required this.isEnabled,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      code: json['materia']?['codigo'] ?? '',
      name: json['materia']?['nombre'] ?? '',
      credits: json['materia']?['creditos'] ?? 0,
      semester: json['semestre'] ?? 0,
      isRequired: json['obligatoria'] ?? false,
      isEnabled: json['habilitada'] ?? false,
    );
  }
}
