import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:inscripcion_frontend/models/career.dart';

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
            // Solo una carrera: seleccionar y saltar a panel
            final data = carrerasData[0]['carrera'];
            final career = Career.fromJson(data);
            provider.selectCareer(career);
            Navigator.pushReplacementNamed(context, '/panel');
          } else {
            // Múltiples carreras: ir a selección
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
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 60,
                        color: UAGRMTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Gestión de Inscripción',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'UAGRM',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Registration Input
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Registro Universitario',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: UAGRMTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _registroController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Ej: 218001234',
                              prefixIcon: Icon(Icons.badge),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese su registro universitario';
                              }
                              if (value.length < 6) {
                                return 'Registro inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(fontSize: 16),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
