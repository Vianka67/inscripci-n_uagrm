import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/widgets/standard_table.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
    }
  }

  // Datos mock para Transacciones basados en la imagen 5
  final List<Map<String, dynamic>> _mockTransacciones = [
    {
      'fecha': '2025-01-15 09:30:00',
      'proceso': 'Inscripción',
      'periodo': '1/2025',
      'via': 'Web',
      'materias': 'MAT101-SA   FIS101-SA   INF210-SA',
      'estado': 'Confirmado',
    },
    {
      'fecha': '2025-01-20 14:15:00',
      'proceso': 'Adición',
      'periodo': '1/2025',
      'via': 'Web',
      'materias': 'INF220-SA',
      'estado': 'Confirmado',
    },
    {
      'fecha': '2024-07-10 08:00:00',
      'proceso': 'Inscripción',
      'periodo': '2/2024',
      'via': 'Ventanilla',
      'materias': 'MAT201-SA   EST301-SA   INF310-SA',
      'estado': 'Confirmado',
    },
    {
      'fecha': '2024-07-15 16:45:00',
      'proceso': 'Retiro',
      'periodo': '2/2024',
      'via': 'Web',
      'materias': 'EST301-SA',
      'estado': 'Confirmado',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Transacciones',
      subtitle: 'Historial de transacciones de inscripción',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StandardTableContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.receipt_long_outlined, color: UAGRMTheme.sidebarBg, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Transacciones Realizadas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: UAGRMTheme.sidebarBg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tabla
                  Expanded(
                    child: _buildTransactionsTable(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTable() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AppTableHeader(
                children: const [
                  Expanded(flex: 3, child: AppHeaderCell('Fecha')),
                  Expanded(flex: 2, child: AppHeaderCell('Proceso', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: AppHeaderCell('Periodo', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: AppHeaderCell('A través de', textAlign: TextAlign.center)),
                  Expanded(flex: 4, child: AppHeaderCell('Materias')),
                  Expanded(flex: 2, child: AppHeaderCell('Estado', textAlign: TextAlign.center)),
                ],
              ),
              // Body
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _mockTransacciones.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final tx = _mockTransacciones[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              tx['fecha'] ?? '',
                              style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: AppProcessBadge(tx['proceso'] ?? ''),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              tx['periodo'] ?? '',
                              style: const TextStyle(fontSize: 13, color: UAGRMTheme.textDark),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: AppProcessBadge(tx['via'] ?? ''),
                          ),
                          Expanded(
                            flex: 4,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: (tx['materias'] as String).split('   ').map((m) => 
                                Text(m.trim(), style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey, fontWeight: FontWeight.w600))
                              ).toList(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(child: AppEstadoBadge(tx['estado'] ?? '')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

}

