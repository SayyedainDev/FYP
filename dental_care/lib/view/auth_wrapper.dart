import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart' as app_auth;
import '../utils/session_manager.dart';
import 'login.dart';

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

  void _initializeApp() async {
    // Wait for the first auth state to resolve (fixes null on refresh)
    final user = await FirebaseAuth.instance.authStateChanges().first;

    // Give AuthProvider a moment to restore the session role from remember_me if necessary
    await Future.delayed(const Duration(milliseconds: 100));

    final provider = context.read<app_auth.AuthProvider>();
    final role = getUserRole() ?? provider.userRole;

    if (!mounted) return;

    if (user != null && role.isNotEmpty) {
      if (role.toLowerCase() == 'doctor' || role.toLowerCase() == 'dentist') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (role.toLowerCase() == 'student') {
        Navigator.pushReplacementNamed(context, '/dashboard');
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
