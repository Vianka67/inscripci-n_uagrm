import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/widgets/main_layout.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Pagos',
      subtitle: 'Gestión de pagos y transacciones universitarias',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildPaymentCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: UAGRMTheme.primaryBlue, width: 2),
            ),
            child: const Icon(Icons.credit_card, size: 36, color: UAGRMTheme.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sistema de Pagos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: UAGRMTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Para realizar pagos de matrícula, aranceles y otros cobros universitarios,\nserá redirigido al sistema de pagos de la UAGRM.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: UAGRMTheme.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://www.uagrm.edu.bo/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el portal de pagos.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ir al Sistema de Pagos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: UAGRMTheme.sidebarPanel, // #1E293B navy oscuro
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
