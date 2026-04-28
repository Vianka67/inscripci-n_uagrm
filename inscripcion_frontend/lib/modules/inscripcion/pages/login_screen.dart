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
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  final String loginQuery = """
    query LoginEstudiante(\$registro: String!, \$contrasena: String!) {
      loginEstudiante(registro: \$registro, contrasena: \$contrasena) {
        registro
        nombreCompleto
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
        
        // Autenticación con el backend
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
          debugPrint('Login Error: ${loginResult.exception.toString()}');
          String errorMsg = 'Credenciales incorrectas';
          
          if (loginResult.exception?.linkException != null) {
            errorMsg = 'Error de conexión con el servidor (192.168.0.116:8000)';
            debugPrint('Link Exception details: ${loginResult.exception?.linkException}');
          } else if (loginResult.exception?.graphqlErrors.isNotEmpty ?? false) {
             errorMsg = loginResult.exception!.graphqlErrors.first.message;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Obtener carreras habilitadas del estudiante tras login exitoso
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
          final String nombreCompleto = loginResult.data?['loginEstudiante']?['nombreCompleto'] ?? '';
          provider.setStudentRegister(_registroController.text, name: nombreCompleto);
          
          // Delay para asegurar actualización de estado
          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/panel');
            }
          });
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
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildWideLayout();
          } else if (constraints.maxWidth >= 600) {
            return _buildTabletLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildTabletLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(160),
                        const SizedBox(height: 16),
                        _buildLoginForm(isWide: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(180),
                        const SizedBox(height: 20),
                        _buildLoginForm(isWide: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double logoSize) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_uagrm.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.school_rounded,
            size: logoSize * 0.6,
            color: UAGRMTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sistema de\nInscripción',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: UAGRMTheme.primaryBlue,
            fontSize: logoSize * 0.18,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final size = MediaQuery.of(context).size;
    final isVerySmall = size.width < 360;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 20 : 32, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(isVerySmall ? 110 : 150),
                      SizedBox(height: isVerySmall ? 12 : 20),
                      _buildLoginForm(isWide: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                color: UAGRMTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistema de Gestión de Inscripción',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
          ],
          
          
          TextFormField(
            controller: _registroController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nro. de Registro',
              hintStyle: TextStyle(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.4), fontSize: 15),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(Icons.person_outline, size: 22, color: UAGRMTheme.primaryBlue),
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
                borderSide: const BorderSide(color: UAGRMTheme.primaryBlue, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingrese su registro';
              if (value.length < 6) return 'Registro inválido';
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: TextStyle(color: UAGRMTheme.primaryBlue.withValues(alpha: 0.4), fontSize: 15),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(Icons.lock_outline, size: 22, color: UAGRMTheme.primaryBlue),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: UAGRMTheme.primaryBlue.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                borderSide: const BorderSide(color: UAGRMTheme.primaryBlue, width: 1.5),
              ),
            ),
            validator: (value) {
               if (value == null || value.isEmpty) return 'Ingrese su contraseña';
               return null;
             },
          ),
          
           const SizedBox(height: 16),
          
          
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: UAGRMTheme.sidebarDeep, // Nuevo Navy más profundo
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
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
          
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: () {},
              hoverColor: Colors.transparent,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
