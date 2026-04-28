import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
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

  final String getTransaccionesQuery = """
    query GetTransacciones(\$nroSerie: Int!) {
      transacciones(nroSerie: \$nroSerie) {
        fechaHora
        gestion
        carrera
        transaccion
        via
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    return MainLayout(
      title: 'Transacciones',
      subtitle: 'Historial de transacciones de inscripción',
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, color: UAGRMTheme.sidebarBg, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Historial de Transacciones Realizadas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: UAGRMTheme.sidebarBg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Query(
                  options: QueryOptions(
                    document: gql(getTransaccionesQuery),
                    variables: {'nroSerie': 999123},
                    fetchPolicy: FetchPolicy.networkOnly,
                  ),
                  builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
                    if (result.isLoading) {
                      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                    }
                    if (result.hasException) {
                      return _buildError(result.exception.toString(), refetch);
                    }

                    final txList = result.data?['transacciones'] as List<dynamic>? ?? [];

                    if (txList.isEmpty) {
                      return _buildEmpty();
                    }

                    return _buildTransactionsTable(txList);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTable(List<dynamic> txList) {
    final isMobile = Responsive.isMobile(context);
    final labels = isMobile
        ? const ['FECHA', 'TIPO', 'VÍA']
        : const ['FECHA/HORA', 'GESTIÓN', 'CARRERA', 'TRANSACCIÓN', 'VÍA'];
    final flexValues = isMobile ? [4, 3, 3] : [3, 2, 4, 3, 2];

    return StandardTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardFlexHeader(labels: labels, flexValues: flexValues),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txList.length,
            itemBuilder: (context, index) {
              final tx = txList[index] as Map<String, dynamic>;
              return StandardFlexRow(
                flexValues: flexValues,
                isLast: index == txList.length - 1,
                cells: [
                  tableText(tx['fechaHora']?.toString() ?? '-', isMobile),
                  if (!isMobile) tableText(tx['gestion']?.toString() ?? '-', isMobile),
                  if (!isMobile) tableText(tx['carrera']?.toString() ?? '-', isMobile, bold: true),
                  AppProcessBadge(tx['transaccion']?.toString() ?? '-'),
                  tableText(tx['via']?.toString() ?? '-', isMobile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, VoidCallback? refetch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: UAGRMTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: refetch, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Sin transacciones registradas', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
