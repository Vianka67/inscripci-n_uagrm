import 'package:flutter/foundation.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
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
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta superior con título
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: UAGRMTheme.sidebarBg, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Historial de Transacciones Realizadas',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: UAGRMTheme.sidebarBg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tabla de transacciones
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _buildTransactionsTable(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTable() {
    final isMobile = Responsive.isMobile(context);
    
    final labels = isMobile 
        ? const ['FECHA', 'PROCESO', 'MATERIAS', 'ESTADO']
        : const ['FECHA', 'PROCESO', 'PERIODO', 'VÍA', 'MATERIAS', 'ESTADO'];
    
    final flexValues = isMobile 
        ? [3, 2, 4, 2]
        : [3, 2, 2, 2, 4, 2];

    return StandardTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardFlexHeader(
            labels: labels,
            flexValues: flexValues,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockTransacciones.length,
            itemBuilder: (context, index) {
              final tx = _mockTransacciones[index];
              return StandardFlexRow(
                flexValues: flexValues,
                isLast: index == _mockTransacciones.length - 1,
                cells: [
                  tableText(tx['fecha'] ?? '', isMobile),
                  AppProcessBadge(tx['proceso'] ?? ''),
                  if (!isMobile)
                    tableText(tx['periodo'] ?? '', isMobile),
                  if (!isMobile)
                    AppProcessBadge(tx['via'] ?? ''),
                  tableText(tx['materias'] ?? '', isMobile),
                  Center(child: AppEstadoBadge(tx['estado'] ?? '')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

}

