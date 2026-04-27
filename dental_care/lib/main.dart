import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:dental_care/view/login.dart';
import 'package:dental_care/view/register.dart';
import 'package:dental_care/view/main_layout.dart';
import 'package:dental_care/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dental_care/service/firebase_service.dart';
import 'package:dental_care/service/shared_prefs_helper.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/app_provider.dart';
import 'package:dental_care/providers/patient_provider.dart';
import 'package:dental_care/providers/scan_provider.dart';
import 'package:dental_care/providers/case_provider.dart';
import 'package:dental_care/providers/navigation_provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/providers/quiz_attempt_provider.dart';
import 'package:dental_care/providers/lecture_notes_provider.dart';
import 'package:dental_care/providers/appointment_provider.dart';
import 'package:dental_care/providers/treatment_plan_provider.dart';
import 'package:dental_care/providers/medical_history_provider.dart';
import 'package:dental_care/providers/analytics_provider.dart';
import 'package:dental_care/providers/audit_log_provider.dart';
import 'package:dental_care/providers/performance_provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/providers/prescription_provider.dart';
import 'package:dental_care/providers/loading_provider.dart';
import 'package:dental_care/utils/firebase_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dental_care/core/config/supabase_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Parallel initialization: run Firebase, Supabase, and SharedPrefs
    await Future.wait([
      _initializeFirebase(),
      _initializeSupabase(),
      _initializeSharedPreferences(),
    ]);

    debugPrint('✅ All services initialized successfully');

    // Run Firebase connection tests (in debug mode only)
    assert(() {
      FirebaseTest.runAllTests().then((results) {
        if (results.values.every((v) => v)) {
          debugPrint('🎉 All Firebase services are operational!');
        }
      });
      return true;
    }());
  } catch (e) {
    debugPrint('❌ Initialization Error: $e');
  }

  final firebaseService = FirebaseService();

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => QuizAttemptProvider()),
        ChangeNotifierProvider(create: (_) => LectureNotesProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => TreatmentPlanProvider()),
        ChangeNotifierProvider(create: (_) => MedicalHistoryProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AuditLogProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
      ],
      child: const MyApp(),
      ),
    ),
  );
}

/// Initialize Firebase in parallel
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase Initialized');
  } catch (e) {
    debugPrint('❌ Firebase Init Error: $e');
    rethrow;
  }
}

/// Initialize Supabase in parallel
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('✅ Supabase Initialized');
  } catch (e) {
    debugPrint('⚠️ Supabase Init Error: $e');
    // We don't rethrow as the app might still work without storage
  }
}

/// Initialize SharedPreferences in parallel
Future<void> _initializeSharedPreferences() async {
  try {
    await SharedPrefsHelper().init();
    debugPrint('✅ SharedPreferences Initialized');
  } catch (e) {
    debugPrint('❌ SharedPrefs Init Error: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PalPath',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/dashboard': (_) => const MainLayout(),
        '/upload': (_) => const MainLayout(),
      },
    );
  }
}
