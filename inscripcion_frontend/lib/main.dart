import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/graphql_service.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/registration_provider.dart';
import 'package:inscripcion_frontend/modules/inscripcion/services/theme_provider.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/login_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/career_selection_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/main_panel_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/enabled_subjects_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/enrollment_slip_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/blocked_status_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/enrollment_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/enrollment_dates_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/pre_enrollment_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/schedule_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/academic_calendar_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/payments_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/maestro_ofertas_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/transactions_screen.dart';
import 'package:inscripcion_frontend/modules/inscripcion/pages/anulaciones_screen.dart';
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: GraphQLProvider(
        client: client,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => MaterialApp(
            title: 'UAGRM Inscripción',
            debugShowCheckedModeBanner: false,
            theme: UAGRMTheme.themeData,
            darkTheme: UAGRMTheme.darkThemeData,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
              '/career': (context) => const CareerSelectionScreen(),
              '/panel': (context) => const MainPanelScreen(),
              '/pre-enrollment': (context) => const PreEnrollmentScreen(),
              '/enabled-subjects': (context) => const EnabledSubjectsScreen(),
              '/enrollment-slip': (context) => const EnrollmentSlipScreen(),
              '/blocked-status': (context) => const BlockedStatusScreen(),
              '/enrollment': (context) => const EnrollmentScreen(),
              '/enrollment-dates': (context) => const EnrollmentDatesScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/calendar': (context) => const AcademicCalendarScreen(),
              '/payments': (context) => const PaymentsScreen(),
              '/transactions': (context) => const TransactionsScreen(),
              '/maestro': (context) => const MaestroOfertasScreen(),
              '/anulaciones': (context) => const AnulacionesScreen(),
            },
          ),
        ),
      ),
    );
  }
}
