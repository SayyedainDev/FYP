import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:dental_care/view/login.dart';
import 'package:dental_care/view/auth_wrapper.dart';
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
import 'package:dental_care/providers/navigation_provider.dart';
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
          // Phase 2.1: Route-Scoped Providers Refactor
          // Kept GLOBAL: Critical systems required at boot/auth layer level.
          ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),

          /* ==============================================================
             REMOVED 15 FEATURE-SPECIFIC PROVIDERS FROM GLOBAL SCOPE HERE.
             They are now dynamically injected inside MainLayout via MultiProvider blocks.
             This prevents the app from downloading thousands of data records over Firestore
             simultaneously on app launch before a user has even logged in.
             (Case, Quiz, Appointment, Treatment, Analytics, Assignment, Lecture, etc...)
             ============================================================== */
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
        '/': (_) => const AuthWrapper(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/dashboard': (_) => const MainLayout(),
        '/upload': (_) => const MainLayout(),
      },
    );
  }
}
