// Provider: holds auth state, exposes methods called by views.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../service/firebase_service.dart';
import '../controller/auth_controller.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _controller;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _loading = false;
  String? uid;
  String? _userName;
  String? _userEmail;
  String _role = 'Dentist';
  bool _rememberMe = false;

  static const _kRememberMeKey = 'remember_me';
  static const _kSavedUidKey = 'saved_uid';
  static const _kSavedEmailKey = 'saved_email';
  static const _kSavedRoleKey = 'saved_role';

  bool get loading => _loading;
  String? get providerId => uid; // Alias for consistency
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String get userRole => _role;
  bool get rememberMe => _rememberMe;

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
    _rememberMe = (await _secureStorage.read(key: _kRememberMeKey)) == 'true';

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      uid = currentUser.uid;
      _userEmail = currentUser.email;
      await _fetchUserData(currentUser.uid);
      if (_rememberMe) {
        await _persistSession();
      }
      notifyListeners();
      return;
    }

    if (_rememberMe) {
      uid = await _secureStorage.read(key: _kSavedUidKey);
      _userEmail = await _secureStorage.read(key: _kSavedEmailKey);
      _role = await _secureStorage.read(key: _kSavedRoleKey) ?? 'Dentist';
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    await _secureStorage.write(
      key: _kRememberMeKey,
      value: _rememberMe.toString(),
    );
    await _secureStorage.write(key: _kSavedUidKey, value: uid ?? '');
    await _secureStorage.write(key: _kSavedEmailKey, value: _userEmail ?? '');
    await _secureStorage.write(key: _kSavedRoleKey, value: _role);
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _kRememberMeKey);
    await _secureStorage.delete(key: _kSavedUidKey);
    await _secureStorage.delete(key: _kSavedEmailKey);
    await _secureStorage.delete(key: _kSavedRoleKey);
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
    // Basic input validation before calling controller
    final email = form['email']?.trim() ?? '';
    final firstName = form['firstName']?.trim() ?? '';
    final lastName = form['lastName']?.trim() ?? '';
    final userId = form['userId']?.trim() ?? '';
    final cnic = form['cnic']?.trim() ?? '';
    final address = form['address']?.trim() ?? '';
    final highestEducation = form['highestEducation']?.trim() ?? '';
    final university = form['university']?.trim() ?? '';
    final yearOfStudy = form['yearOfStudy']?.trim() ?? '';
    final batchCode = form['batchCode']?.trim() ?? '';
    final role = form['role'] ?? 'Dentist';

    if (userId.isEmpty) throw Exception('Professional ID is required');
    if (firstName.isEmpty) throw Exception('First name is required');
    if (lastName.isEmpty) throw Exception('Last name is required');
    if (cnic.isEmpty) throw Exception('License / CNIC is required');
    if (address.isEmpty) throw Exception('Practice address is required');
    if (highestEducation.isEmpty) {
      throw Exception('Highest education is required');
    }
    if (email.isEmpty) throw Exception('Email is required');
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) throw Exception('Enter a valid email');
    if (password.trim().length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    _loading = true;
    notifyListeners();
    try {
      final id = await _controller.register(
        email: email,
        password: password,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        cnic: cnic,
        address: address,
        highestEducation: highestEducation,
        role: role,
        university: university,
        yearOfStudy: yearOfStudy,
        batchCode: batchCode,
      );
      uid = id;
      _role = role;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
    bool studentOnly = false,
  }) async {
    // Basic validation
    final e = email.trim();
    final p = password;
    if (e.isEmpty) throw Exception('Email is required');
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(e)) throw Exception('Enter a valid email');
    if (p.isEmpty) throw Exception('Password is required');
    if (p.length < 8) throw Exception('Password must be at least 8 characters');

    _loading = true;
    notifyListeners();
    try {
      final id = await _controller.login(email: e, password: p);
      uid = id;
      _userEmail = e;
      await _fetchUserData(id);

      if (studentOnly && _role.toLowerCase() != 'student') {
        await logout();
        throw Exception('teacher_account_detected');
      }
      if (!studentOnly && _role.toLowerCase() == 'student') {
        await logout();
        throw Exception('student_account_detected');
      }

      _rememberMe = rememberMe;
      if (_rememberMe) {
        await _persistSession();
      } else {
        await _clearSession();
      }
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
      _rememberMe = false;
      await _clearSession();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final target = email.trim();
    if (target.isEmpty) throw Exception('Email is required');
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(target)) throw Exception('Enter a valid email');

    _loading = true;
    notifyListeners();
    try {
      await _controller.sendPasswordResetEmail(target);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> resendEmailVerification() async {
    _loading = true;
    notifyListeners();
    try {
      await _controller.resendEmailVerification();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshEmailVerificationStatus() async {
    _loading = true;
    notifyListeners();
    try {
      return await _controller.refreshEmailVerificationStatus();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
