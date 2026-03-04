import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:inscripcion_frontend/models/career.dart';
import 'package:inscripcion_frontend/utils/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _registroController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final String getCarrerasQuery = """
    query GetCarreras(\$registro: String!) {
      misCarreras(registro: \$registro) {
        carrera {
          codigo
          nombre
          facultad
        }
      }
    }
  """;

  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final client = GraphQLProvider.of(context).value;
        final QueryResult result = await client.query(
          QueryOptions(
            document: gql(getCarrerasQuery),
            variables: {'registro': _registroController.text},
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );

        if (result.hasException) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al conectar con el servidor')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final List carrerasData = result.data?['misCarreras'] ?? [];

        if (carrerasData.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro no encontrado o sin carreras')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final provider = context.read<RegistrationProvider>();
        provider.setStudentRegister(_registroController.text);

        if (mounted) {
          if (carrerasData.length == 1) {
            final data = carrerasData[0]['carrera'];
            final career = Career.fromJson(data);
            provider.selectCareer(career);
            Navigator.pushReplacementNamed(context, '/panel');
          } else {
            Navigator.pushReplacementNamed(context, '/career');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inesperado: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mobile: columna única; Tablet + Desktop: dos columnas
    if (Responsive.isMobile(context)) return _buildMobileLayout();
    return _buildWideLayout();
  }

  // ─── LAYOUT AMPLIO (Tablet + Desktop) — 2 columnas ───────────────────────────

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Columna izquierda: branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.school, size: 48, color: UAGRMTheme.primaryBlue),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Universidad Autónoma\nGabriel René Moreno',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sistema de Gestión de Inscripción\nAcadémica en línea',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildFeatureItem(Icons.check_circle_outline, 'Inscripción en línea'),
                      const SizedBox(height: 12),
                      _buildFeatureItem(Icons.calendar_month_outlined, 'Consulta de fechas'),
                      const SizedBox(height: 12),
                      _buildFeatureItem(Icons.description_outlined, 'Boleta digital'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Columna derecha: formulario
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF4F6F9),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLoginCard(isWide: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  // ─── LAYOUT MÓVIL (original) ─────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [UAGRMTheme.primaryBlue, Color(0xFF1565C0)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.school, size: 60, color: UAGRMTheme.primaryBlue),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Gestión de Inscripción',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text('UAGRM', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 48),
                    _buildLoginCard(isWide: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── FORMULARIO COMPARTIDO ────────────────────────────────────────────────────

  Widget _buildLoginCard({required bool isWide}) {
    Widget formContent = Form(
      key: isWide ? _formKey : GlobalKey<FormState>(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWide) ...[
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: UAGRMTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ingresa tu número de registro universitario',
              style: TextStyle(fontSize: 13, color: UAGRMTheme.textGrey),
            ),
            const SizedBox(height: 28),
          ] else ...[
            const Text(
              'Registro Universitario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _registroController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: isWide ? 14 : 16),
            decoration: InputDecoration(
              hintText: 'Ej: 218001234',
              labelText: isWide ? 'Nro. de Registro' : null,
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isWide ? 12 : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingrese su registro universitario';
              if (value.length < 6) return 'Registro inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isWide ? 44 : 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isWide ? 0 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isWide ? 8 : 12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Ingresar',
                      style: TextStyle(fontSize: isWide ? 14 : 16),
                    ),
            ),
          ),
          if (isWide) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: UAGRMTheme.textGrey),
                const SizedBox(width: 6),
                const Text(
                  'Tu registro está en tu carnet universitario',
                  style: TextStyle(fontSize: 12, color: UAGRMTheme.textGrey),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (isWide) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: formContent,
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: formContent,
    );
  }
}
