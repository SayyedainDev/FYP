import 'package:dental_care/view/login.dart';
import 'package:dental_care/view/register.dart';
import 'package:dental_care/view/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dental_care/service/firebase_service.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/app_provider.dart';
import 'package:dental_care/providers/patient_provider.dart';
import 'package:dental_care/providers/scan_provider.dart';
import 'package:dental_care/providers/case_provider.dart';
import 'package:dental_care/providers/navigation_provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/utils/firebase_test.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase Initialized Successfully');

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
    debugPrint('❌ Firebase Initialization Error: $e');
    debugPrint('Please check your Firebase configuration.');
  }

  final firebaseService = FirebaseService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dental Care',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
        ),
      ),
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
