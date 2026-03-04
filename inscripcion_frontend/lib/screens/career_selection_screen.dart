import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/models/career.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/utils/responsive_helper.dart';

class CareerSelectionScreen extends StatefulWidget {
  const CareerSelectionScreen({super.key});

  @override
  State<CareerSelectionScreen> createState() => _CareerSelectionScreenState();
}

class _CareerSelectionScreenState extends State<CareerSelectionScreen> {
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
    final isLarge = Responsive.isTabletOrDesktop(context);

    return Scaffold(
      backgroundColor: isLarge ? const Color(0xFFF4F6F9) : Colors.white,
      appBar: AppBar(
        title: isLarge
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 20),
                  SizedBox(width: 8),
                  Text('Gestión de Inscripción — UAGRM'),
                ],
              )
            : Column(
                children: [
                  const Icon(Icons.school, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Gestión de Inscripción',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
        bottom: isLarge
            ? null
            : PreferredSize(
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
                  Text('Error al cargar carreras:\n${result.exception.toString()}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
                ],
              ),
            );
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List carrerasData = result.data?['misCarreras'] ?? [];

          if (isLarge) {
            // Tablet + Desktop: lista centrada con ancho máximo
            final maxW = Responsive.isDesktop(context) ? 600.0 : 500.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccionar Carrera',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: UAGRMTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tienes ${carrerasData.length} carrera(s) registrada(s). Elige una para continuar.',
                            style: const TextStyle(fontSize: 13, color: UAGRMTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: carrerasData.length,
                        itemBuilder: (context, index) {
                          final career = Career.fromJson(carrerasData[index]['carrera']);
                          return _CareerCard(career: career);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Móvil: lista original
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: carrerasData.length,
            itemBuilder: (context, index) {
              final career = Career.fromJson(carrerasData[index]['carrera']);
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
    final isLarge = Responsive.isTabletOrDesktop(context);

    return GestureDetector(
      onTap: () async {
        context.read<RegistrationProvider>().selectCareer(career);
        await Future.delayed(const Duration(milliseconds: 200));
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/panel');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: isLarge ? 10 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isLarge ? 8 : 12),
          border: isSelected
              ? Border.all(color: UAGRMTheme.primaryBlue, width: 2)
              : Border.all(color: isLarge ? Colors.grey.shade200 : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: isSelected ? UAGRMTheme.primaryBlue.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isLarge ? 14 : 20),
        child: Row(
          children: [
            Container(
              width: isLarge ? 40 : 56,
              height: isLarge ? 40 : 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book,
                color: UAGRMTheme.primaryBlue,
                size: isLarge ? 22 : 30,
              ),
            ),
            SizedBox(width: isLarge ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    career.name,
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: UAGRMTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    career.faculty,
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 14,
                      color: UAGRMTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: UAGRMTheme.successGreen, size: 22)
            else
              const Icon(Icons.chevron_right, color: UAGRMTheme.textGrey, size: 18),
          ],
        ),
      ),
    );
  }
}
