import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/session_manager.dart';
import 'login.dart';
import 'student_lms_dashboard.dart' as student_dashboard;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() {
    final user = FirebaseAuth.instance.currentUser;
    final role = getUserRole(); // Uses our session_manager.dart

    if (user != null && role != null) {
      if (role.toLowerCase() == 'doctor' || role.toLowerCase() == 'dentist') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (role.toLowerCase() == 'student') {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const student_dashboard.StudentLMSDashboard()));
      } else {
        // Unknown role, fallback to doctor/dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      // If either user or role is null, we shouldn't be logged in
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while checking auth state
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
