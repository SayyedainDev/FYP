// Provider: holds auth state, exposes methods called by views.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/firebase_service.dart';
import '../controller/auth_controller.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _controller;
  bool _loading = false;
  String? uid;
  String? _userName;
  String? _userEmail;
  String _role = 'Dentist';

  bool get loading => _loading;
  String? get providerId => uid; // Alias for consistency
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String get userRole => _role;

  // Get current Firebase user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Get current Firebase user
  User? get user => FirebaseAuth.instance.currentUser;

  // Get display name with Dr. title
  String get displayName {
    if (_userName != null && _userName!.isNotEmpty) {
      return 'Dr. $_userName';
    }
    return 'Dr. User';
  }

  // Get initials for avatar
  String get initials {
    if (_userName != null && _userName!.isNotEmpty) {
      final parts = _userName!.trim().split(' ');
      if (parts.isEmpty) return 'Dr';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return 'Dr';
  }

  AuthProvider(FirebaseService service)
    : _controller = AuthController(service) {
    // Initialize with current user if already logged in
    _initializeCurrentUser();
  }

  void _initializeCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      uid = currentUser.uid;
      _userEmail = currentUser.email;
      await _fetchUserData(currentUser.uid);
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final firstName = data['firstName'] as String?;
          final lastName = data['lastName'] as String?;

          if (firstName != null && lastName != null) {
            _userName = '$firstName $lastName';
          } else if (firstName != null) {
            _userName = firstName;
          } else {
            _userName = _userEmail?.split('@').first;
          }

          _role = (data['role'] as String?)?.trim().isNotEmpty == true
              ? (data['role'] as String).trim()
              : 'Dentist';
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _userName = _userEmail?.split('@').first;
      _role = 'Dentist';
    }
  }

  Future<void> register(Map<String, String> form, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final id = await _controller.register(
        email: form['email']!,
        password: password,
        userId: form['userId']!,
        firstName: form['firstName']!,
        lastName: form['lastName']!,
        cnic: form['cnic']!,
        address: form['address']!,
        highestEducation: form['highestEducation']!,
        role: form['role'] ?? 'Dentist',
      );
      uid = id;
      _role = form['role'] ?? 'Dentist';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final id = await _controller.login(email: email, password: password);
      uid = id;
      _userEmail = email;
      await _fetchUserData(id);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await _controller.logout();
      uid = null;
      _userName = null;
      _userEmail = null;
      _role = 'Dentist';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
