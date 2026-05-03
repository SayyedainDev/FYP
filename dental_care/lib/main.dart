import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:dental_care/view/login.dart';
import 'package:dental_care/view/auth_wrapper.dart';
import 'package:dental_care/view/register.dart';
import 'package:dental_care/view/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dental_care/service/firebase_service.dart';
import 'package:dental_care/service/shared_prefs_helper.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/core/config/supabase_config.dart';

import 'package:dental_care/providers/navigation_provider.dart';
import 'package:dental_care/providers/loading_provider.dart';
import 'package:dental_care/providers/theme_provider.dart';
import 'package:dental_care/utils/global_error_handler.dart';
import 'package:dental_care/utils/firebase_test.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Sequential initialization for Supabase to ensure it's ready before the app starts
    await _initializeFirebase();
    await _initializeSupabase();
    await _initializeSharedPreferences();

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
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),

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
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase Initialized');
  } catch (e) {
    debugPrint('❌ Supabase Init Error: $e');
    // Rethrow to ensure we don't start the app in a broken state if Supabase is critical
    rethrow;
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
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, _) {
        // Update theme based on user role when user changes
        if (authProvider.user != null) {
          final userRole = ThemeProvider.parseUserRole(authProvider.userRole);
          if (themeProvider.userRole != userRole) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeProvider.setUserRole(userRole);
            });
          }
        }

        return MaterialApp(
          navigatorKey: GlobalErrorHandler.instance.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'PalPath',
          theme: themeProvider.currentTheme,
          darkTheme: themeProvider.currentDarkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (_) => const AuthWrapper(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/dashboard': (_) => const MainLayout(),
            '/upload': (_) => const MainLayout(),
          },
        );
      },
    );
  }
}
