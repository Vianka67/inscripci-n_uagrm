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
    // Manejo ultra defensivo de datos nulos para evitar errores de mapeo
    final materia = json['materia'] as Map<String, dynamic>?;
    
    return Subject(
      code: materia?['codigo']?.toString() ?? '',
      name: materia?['nombre']?.toString() ?? 'Sin nombre',
      credits: int.tryParse(materia?['creditos']?.toString() ?? '0') ?? 0,
      semester: int.tryParse(json['semestre']?.toString() ?? '0') ?? 0,
      isRequired: json['obligatoria'] == true || json['obligatoria'] == 1,
      isEnabled: json['habilitada'] == true || json['habilitada'] == 1,
    );
  }
}
