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
  final _passwordController = TextEditingController(); // Nuevo campo dummy según diseño
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  final String loginQuery = """
    query LoginEstudiante(\$registro: String!, \$contrasena: String!) {
      loginEstudiante(registro: \$registro, contrasena: \$contrasena) {
        registro
        nombre
      }
    }
  """;

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

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final client = GraphQLProvider.of(context).value;
        
        // 1. Validar login con contraseña
        final QueryResult loginResult = await client.query(
          QueryOptions(
            document: gql(loginQuery),
            variables: {
              'registro': _registroController.text,
              'contrasena': _passwordController.text,
            },
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );

        if (loginResult.hasException) {
          String errorMsg = 'Credenciales incorrectas';
          if (loginResult.exception?.linkException != null) {
            errorMsg = 'Error de conexión con el servidor';
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 2. Si el login fue exitoso, obtener las carreras
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
              const SnackBar(content: Text('Error al cargar carreras del estudiante')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }


        final List carrerasData = result.data?['misCarreras'] ?? [];

        if (carrerasData.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usted no cuenta con carreras activas en el sistema')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        if (mounted) {
          final provider = context.read<RegistrationProvider>();
          provider.setStudentRegister(_registroController.text);
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
    if (Responsive.isMobile(context)) return _buildMobileLayout();
    return _buildWideLayout();
  }

  Widget _buildWideLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Panel Izquierdo: Institucional ──
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF003366),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Marca de agua: escudo grande sutil
                  Positioned(
                    left: -120,
                    bottom: -80,
                    child: Opacity(
                      opacity: 0.10, // Un poco más visible para igualar referencia
                      child: Image.asset('assets/images/logo_uagrm.png', width: 650, height: 650,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo pequeño en círculo blanco + texto arriba
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset('assets/images/logo_uagrm.png', fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Color(0xFF003366), size: 28)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('UAGRM', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                Text('Autónoma Gabriel René Moreno', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text('Universidad Autónoma\nGabriel René Moreno',
                          style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1.1)),
                        const SizedBox(height: 16),
                        Text('Accede a tu inscripción académica',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18)),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

      // ── Panel Derecho: Formulario ──
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildLoginForm(isWide: true),
                      ),
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

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     const SizedBox(height: 40),
                    // Logo UAGRM centrado directo (ya tiene líneas azules sobre transparente)
                    Image.asset(
                      'assets/images/logo_uagrm.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 80, color: Color(0xFF003366)),
                    ),
                    const SizedBox(height: 32),
                    
                    // Titulo
                    const Text(
                      'Sistema de\nInscripción',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF003366),
                        fontSize: 32,
                        fontWeight: FontWeight.w900, // Extra Bold
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    _buildLoginForm(isWide: false),
                  ],
                ),
              ),
            ),
            // Footer text pinned at bottom para movil
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () {},
                hoverColor: Colors.transparent,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm({required bool isWide}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWide) ...[
            const Text(
              'Iniciar Sesión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF001529), // Azul oscuro
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistema de Gestión de Inscripción',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 36),
          ],
          
          // Campo Registro
          TextFormField(
            controller: _registroController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nro. de Registro',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Icon(Icons.person_outline, size: 22, color: Colors.black87),
              ),
              filled: true,
              fillColor: Colors.white, // Fondo blanco para los inputs
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.black54, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.black54, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingrese su registro';
              if (value.length < 6) return 'Registro inválido';
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campo Contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Icon(Icons.lock_outline, size: 22, color: Colors.black87),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.black87,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.black54, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.black54, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
              ),
            ),
            validator: (value) {
               if (value == null || value.isEmpty) return 'Ingrese su contraseña';
               return null;
             },
          ),
          
          const SizedBox(height: 24),
          
          // Boton Ingresar
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002244), // Azul muy oscuro (Navy)
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Botón estilo píldora
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Ingresar',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                    ),
            ),
          ),
          
          if (isWide) ...[
            const SizedBox(height: 32),
            Center(
              child: InkWell(
                onTap: () {},
                hoverColor: Colors.transparent,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
