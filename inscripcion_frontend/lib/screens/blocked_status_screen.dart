import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/widgets/web_page_header.dart';
import 'package:inscripcion_frontend/utils/responsive_helper.dart';

class BlockedStatusScreen extends StatefulWidget {
  const BlockedStatusScreen({super.key});

  @override
  State<BlockedStatusScreen> createState() => _BlockedStatusScreenState();
}

class _BlockedStatusScreenState extends State<BlockedStatusScreen> {
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

  final String getBlockStatusQuery = """
    query GetBlockStatus(\$registro: String!) {
      bloqueoEstudiante(registro: \$registro) {
        bloqueado
        bloqueos {
          motivo
          fechaDesbloqueo
        }
      }
    }
  """;

  final Map<String, dynamic> blockData = {
    'motivo': 'Deuda pendiente de matrícula',
    'fechaDesbloqueo': '28/07/2024',
  };

  @override
  Widget build(BuildContext context) {
    final isLarge = Responsive.isTabletOrDesktop(context);

    if (isLarge) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebPageHeader(
                title: 'Estado de Bloqueo',
                icon: Icons.lock_outline,
                subtitle: 'Información sobre bloqueos activos en tu cuenta',
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.isDesktop(context) ? 800 : 640,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                      child: _buildWebContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Móvil: diseño original
    return Scaffold(
      appBar: AppBar(title: const Text('Bloqueo'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_outline, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text('BLOQUEO',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildMobileTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebContent() {
    final bool isBlocked = blockData['motivo'] != null && (blockData['motivo'] as String).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isBlocked ? UAGRMTheme.errorRed.withValues(alpha: 0.06) : UAGRMTheme.successGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBlocked ? UAGRMTheme.errorRed.withValues(alpha: 0.3) : UAGRMTheme.successGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isBlocked ? Icons.lock_outline : Icons.check_circle_outline,
                color: isBlocked ? UAGRMTheme.errorRed : UAGRMTheme.successGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBlocked ? 'Cuenta con bloqueo activo' : 'Sin bloqueos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isBlocked ? UAGRMTheme.errorRed : UAGRMTheme.successGreen,
                      ),
                    ),
                    Text(
                      isBlocked
                          ? 'Resuelve el bloqueo para habilitar la inscripción'
                          : 'Tu cuenta está habilitada para inscribirse',
                      style: const TextStyle(fontSize: 12, color: UAGRMTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isBlocked) ...[
          const Text('Detalle de Bloqueos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: UAGRMTheme.primaryBlue,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text('MOTIVO DEL BLOQUEO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
                      Expanded(flex: 2, child: Text('FECHA DE DESBLOQUEO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(blockData['motivo'] ?? '', style: const TextStyle(fontSize: 13))),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Text(
                              blockData['fechaDesbloqueo'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileTable() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: UAGRMTheme.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('MOTIVO DEL BLOQUEO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('FECHA DE DESBLOQUEO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(blockData['motivo'] ?? '', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text(blockData['fechaDesbloqueo'] ?? '', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
