import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/models/career.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';

class CareerSelectionScreen extends StatefulWidget {
  const CareerSelectionScreen({super.key});

  @override
  State<CareerSelectionScreen> createState() => _CareerSelectionScreenState();
}

class _CareerSelectionScreenState extends State<CareerSelectionScreen> {
  // Query para obtener registros asociados (carreras)
  final String getCareersQuery = """
    query GetCarreras(\$registro: String!) {
      misCarreras(registro: \$registro) {
        carrera {
          codigo
          nombre
          facultad
          duracionSemestres
        }
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Icon(Icons.school, size: 28),
            const SizedBox(height: 4),
            Text(
              'Gestión de Inscripción',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'SELECCIONE CARRERA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getCareersQuery),
          variables: {'registro': provider.studentRegister ?? ''},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error al cargar carreras: \n${result.exception.toString()}'),
                  ElevatedButton(
                    onPressed: refetch,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List carrerasData = result.data?['misCarreras'] ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: carrerasData.length,
            itemBuilder: (context, index) {
              final item = carrerasData[index];
              final career = Career.fromJson(item['carrera']);
              return _CareerCard(career: career);
            },
          );
        },
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  final Career career;

  const _CareerCard({required this.career});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final isSelected = provider.selectedCareer?.code == career.code;

    return GestureDetector(
      onTap: () async {
        context.read<RegistrationProvider>().selectCareer(career);
        // Pequeño delay para mostrar la animación de selección
        await Future.delayed(const Duration(milliseconds: 300));
        // Navegar al panel principal
        if (context.mounted) {
           Navigator.pushReplacementNamed(context, '/panel');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: UAGRMTheme.primaryBlue, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: isSelected ? UAGRMTheme.primaryBlue.withOpacity(0.3) : Colors.black12,
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
             Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book, // Icono genérico por ahora
                color: UAGRMTheme.primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    career.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: UAGRMTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    career.faculty,
                    style: const TextStyle(
                      fontSize: 14,
                      color: UAGRMTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
             if (isSelected)
              const Icon(Icons.check_circle, color: UAGRMTheme.successGreen, size: 28),
          ],
        ),
      ),
    );
  }
}
