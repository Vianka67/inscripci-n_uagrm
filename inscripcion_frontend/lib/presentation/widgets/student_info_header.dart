import 'package:flutter/material.dart';

class StudentInfoHeader extends StatelessWidget {
  final String studentName;
  final String career;
  final String semester;
  final String registrationNumber;

  const StudentInfoHeader({
    super.key,
    required this.studentName,
    required this.career,
    required this.semester,
    required this.registrationNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.black54,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTUDIANTE: $studentName',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTRO: $registrationNumber',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'CARRERA: $career',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'SEMESTRE: $semester',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
