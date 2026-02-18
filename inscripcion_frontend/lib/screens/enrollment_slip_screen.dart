import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';

class EnrollmentSlipScreen extends StatelessWidget {
  const EnrollmentSlipScreen({super.key});

  final String getEnrollmentQuery = """
    query GetEnrollment(\$registro: String!, \$codigoCarrera: String) {
      inscripcionCompleta(registro: \$registro, codigoCarrera: \$codigoCarrera) {
        id
        estudiante {
          registro
          nombreCompleto
        }
        periodoAcademico {
          codigo
          nombre
        }
        fechaInscripcionAsignada
        fechaInscripcionRealizada
        estado
        boletaGenerada
        numeroBoleta
        materiasInscritas {
          materia {
            codigo
            nombre
            creditos
          }
          grupo
        }
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final studentRegister = provider.studentRegister;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boleta de Inscripción'),
        centerTitle: true,
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getEnrollmentQuery),
          variables: {
            'registro': studentRegister ?? '',
            'codigoCarrera': provider.selectedCareer?.code,
          },
        ),
        builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${result.exception.toString()}'),
                  const SizedBox(height: 16),
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

          final data = result.data?['inscripcionCompleta'];
          if (data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay inscripción registrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final materiasInscritas = data['materiasInscritas'] as List<dynamic>? ?? [];
          final totalCredits = materiasInscritas.fold<int>(
            0,
            (sum, item) => sum + (item['materia']?['creditos'] as int? ?? 0),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Card(
                color: UAGRMTheme.primaryBlue,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BOLETA DE INSCRIPCIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['numeroBoleta'] ?? 'Sin número',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Student Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Estudiante:', data['estudiante']?['nombreCompleto'] ?? ''),
                      _InfoRow('Registro:', data['estudiante']?['registro']?.toString() ?? ''),
                      _InfoRow('Periodo:', data['periodoAcademico']?['nombre'] ?? ''),
                      _InfoRow('Estado:', data['estado'] ?? ''),
                      if (data['fechaInscripcionRealizada'] != null)
                        _InfoRow('Fecha Inscripción:', data['fechaInscripcionRealizada']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary
              Card(
                color: UAGRMTheme.primaryBlue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem('Materias', materiasInscritas.length.toString()),
                      _SummaryItem('Créditos', totalCredits.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Table
              const Text(
                'Detalle de Pago',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'CONCEPTO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'MONTO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ESTADO DE PAGO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    if (materiasInscritas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay materias inscritas',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...materiasInscritas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final materia = item['materia'];
                        final isEven = index % 2 == 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.grey.shade100 : Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  materia?['nombre'] ?? '',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Bs. ${(materia?['creditos'] ?? 0) * 50}',
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Bs. ${(materia?['creditos'] ?? 0) * 50}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: data['boletaGenerada'] == true
                                          ? UAGRMTheme.successGreen
                                          : UAGRMTheme.warningOrange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      data['boletaGenerada'] == true ? 'PAGADO' : 'PENDIENTE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: UAGRMTheme.primaryBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
