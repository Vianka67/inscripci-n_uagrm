import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/services/graphql_service.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';
import 'package:inscripcion_frontend/screens/login_screen.dart';
import 'package:inscripcion_frontend/screens/career_selection_screen.dart';
import 'package:inscripcion_frontend/screens/main_panel_screen.dart';
import 'package:inscripcion_frontend/screens/enabled_subjects_screen.dart';
import 'package:inscripcion_frontend/screens/enrollment_slip_screen.dart';
import 'package:inscripcion_frontend/screens/blocked_status_screen.dart';
import 'package:inscripcion_frontend/screens/enrollment_screen.dart';
import 'package:inscripcion_frontend/screens/enrollment_dates_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar barra de estado para que sea legible
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Barra transparente
      statusBarIconBrightness: Brightness.dark, // Iconos oscuros (para fondo claro)
      statusBarBrightness: Brightness.light, // Para iOS
    ),
  );
  
  runApp(const UAGRMApp());
}

class UAGRMApp extends StatelessWidget {
  const UAGRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = GraphQLService.initClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: GraphQLProvider(
        client: client,
        child: MaterialApp(
          title: 'UAGRM Inscripción',
          debugShowCheckedModeBanner: false,
          theme: UAGRMTheme.themeData,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/career': (context) => const CareerSelectionScreen(),
            '/panel': (context) => const MainPanelScreen(),
            '/enabled-subjects': (context) => const EnabledSubjectsScreen(),
            '/enrollment-slip': (context) => const EnrollmentSlipScreen(),
            '/blocked-status': (context) => const BlockedStatusScreen(),
            '/enrollment': (context) => const EnrollmentScreen(),
            '/enrollment-dates': (context) => const EnrollmentDatesScreen(),
          },
        ),
      ),
    );
  }
}
