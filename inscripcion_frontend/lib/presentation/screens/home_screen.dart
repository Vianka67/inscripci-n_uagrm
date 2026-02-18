import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/presentation/widgets/student_info_header.dart';
import 'package:inscripcion_frontend/presentation/widgets/menu_button.dart';
import 'package:inscripcion_frontend/presentation/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UAGRM - Portal Estudiante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const StudentInfoHeader(
            studentName: 'JUAN PEREZ',
            career: 'ING. SISTEMAS',
            semester: '1/2026',
            registrationNumber: '215000000',
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                MenuButton(
                  title: 'Inscripción de Materias',
                  icon: Icons.app_registration,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Módulo de inscripción')),
                    );
                  },
                ),
                MenuButton(
                  title: 'Mi Horario',
                  icon: Icons.calendar_today,
                  onTap: () {},
                ),
                MenuButton(
                  title: 'Avance Académico',
                  icon: Icons.timeline,
                  onTap: () {},
                ),
                MenuButton(
                  title: 'Perfil',
                  icon: Icons.person,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
