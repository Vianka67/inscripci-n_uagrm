import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/career.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';

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
          String errorMsg = 'Error al conectar con el servidor';
          final exception = result.exception;
          if (exception != null) {
            if (exception.linkException != null) {
              errorMsg = 'Sin conexión al servidor: ${exception.linkException.toString()}';
            } else if (exception.graphqlErrors.isNotEmpty) {
              errorMsg = 'Error: ${exception.graphqlErrors.first.message}';
            }
          }
          // ignore: avoid_print
          print('GraphQL Exception: $exception');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), duration: const Duration(seconds: 8)),
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

        if (mounted) {
          final provider = context.read<RegistrationProvider>();
          provider.setStudentRegister(_registroController.text);
          // Omitimos cargar la carrera aquí. El Sidebar auto-cargará la primera o dejará elegir.
          Navigator.pushReplacementNamed(context, '/panel');
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
    // Móvil: columna única; Tablet + Escritorio: dos columnas
    if (Responsive.isMobile(context)) return _buildMobileLayout();
    return _buildWideLayout();
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [UAGRMTheme.primaryBlue, UAGRMTheme.primaryBlue, UAGRMTheme.primaryRed, UAGRMTheme.primaryRed],
                  stops: [0.0, 0.5, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/images/image_0.jpeg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.school, size: 80, color: UAGRMTheme.primaryBlue);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Universidad Autónoma\nGabriel René Moreno',
                        textAlign: TextAlign.center,
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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureItem(Icons.check_circle_outline, 'Inscripción en línea'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureItem(Icons.calendar_month_outlined, 'Consulta de fechas'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureItem(Icons.description_outlined, 'Boleta digital'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

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

  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [UAGRMTheme.primaryBlue, UAGRMTheme.primaryBlue, UAGRMTheme.primaryRed, UAGRMTheme.primaryRed],
              stops: [0.0, 0.5, 0.5, 1.0],
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
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/image_0.jpeg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.school, size: 70, color: UAGRMTheme.primaryBlue);
                          },
                        ),
                      ),
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
              hintText: '',
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
              color: Colors.black.withValues(alpha: 0.08),
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
