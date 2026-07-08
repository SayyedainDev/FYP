// Provider: holds auth state, exposes methods called by views.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../service/firebase_service.dart';
import '../service/cache_service.dart';
import '../service/shared_prefs_helper.dart';
import '../controller/auth_controller.dart';
import '../utils/session_manager.dart';

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
  String get userRole {
    // ALWAYS fetch from session storage to guarantee tab isolation
    final sessionRole = getUserRole();
    if (sessionRole != null && sessionRole.isNotEmpty) {
      _role = sessionRole;
    } else {
      // Force role validation: if no role in session, we shouldn't be logged in
      if (uid != null) {
        Future.microtask(() => logout());
      }
    }
    return _role;
  }

  bool get rememberMe => _rememberMe;

  // Get current Firebase user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Get current Firebase user
  User? get user => FirebaseAuth.instance.currentUser;

  // Get display name (full name for students, Dr. + name for dentists)
  String get displayName {
    if (_userName != null && _userName!.isNotEmpty) {
      if (_role.toLowerCase() == 'student') {
        return _userName!;
      } else {
        return 'Dr. $_userName';
      }
    }
    return _role.toLowerCase() == 'student' ? 'Student User' : 'Dr. User';
  }

  // Get initials for avatar
  String get initials {
    final parts = (_userName ?? '')
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return _role.toLowerCase() == 'student' ? 'S' : 'D';
  }

  AuthProvider(FirebaseService service)
      : _controller = AuthController(service) {
    // Initialize with current user if already logged in
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    _rememberMe = (await _secureStorage.read(key: _kRememberMeKey)) == 'true';

    final currentUser = FirebaseAuth.instance.currentUser;
    final sessionRole = getUserRole();

    // Recover session from SharedPreferences if missing (fixes student refresh bug)
    if (currentUser != null && (sessionRole == null || sessionRole.isEmpty)) {
      try {
        final prefs = SharedPrefsHelper();
        final savedRole =
            await _secureStorage.read(key: _kSavedRoleKey) ?? 'Dentist';
        if (savedRole.isNotEmpty) {
          saveUserRole(savedRole); // put it back into session storage
        }
        uid = currentUser.uid;
        _userEmail = currentUser.email;
        _role = savedRole;
        final cachedName = prefs.getString(SharedPrefsHelper.keyUserName);
        if (cachedName != null) {
          _userName = cachedName;
        }
        notifyListeners();
        // background fetch to sync data
        _fetchUserData(currentUser.uid).then((_) => notifyListeners());
        return;
      } catch (e) {
        debugPrint('Error recovering from preferences: $e');
      }
    }

    if (currentUser != null && sessionRole != null) {
      uid = currentUser.uid;
      _userEmail = currentUser.email;
      _role = sessionRole;
      await _fetchUserData(currentUser.uid);
      if (_rememberMe) {
        await _persistSession();
      }
      notifyListeners();
      return;
    } else if (currentUser != null && _rememberMe) {
      // Fallback: If sessionRole is missing but user checked "Remember Me",
      // load role from secureStorage to restore session (e.g. after full browser close)
      final savedRole = await _secureStorage.read(key: _kSavedRoleKey);
      if (savedRole != null && savedRole.isNotEmpty) {
        saveUserRole(savedRole); // Restore to sessionStorage
        uid = currentUser.uid;
        _userEmail = currentUser.email;
        _role = savedRole;
        await _fetchUserData(currentUser.uid);
        notifyListeners();
        return;
      } else {
        await logout();
      }
      _role = 'Dentist';
    }

    // DO NOT fallback to secureStorage / localStorage because it breaks multi-tab isolation.
    // We only use that if explicitly allowed for single-session environments, but web needs strict tab isolation.

    notifyListeners();
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
      final cacheService = CacheService();
      final prefs = SharedPrefsHelper();

      // Try to fetch with caching (5 minute cache)
      final doc = await cacheService.fetchDocumentWithCache(
        'user_profile_$userId',
        FirebaseFirestore.instance.collection('users').doc(userId),
        cacheDuration: const Duration(minutes: 5),
      );

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
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

          // Cache user data to SharedPreferences for fast retrieval
          await prefs.cacheUserBasicInfo(
            uid: userId,
            email: _userEmail ?? '',
            name: _userName ?? '',
            role: _role,
          );
          prefs.setCacheTimestamp('user_profile_$userId');
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
      // Same tab-scoped persistence as login so the session behaves identically
      await FirebaseAuth.instance.setPersistence(Persistence.SESSION);

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
      _userEmail = email;
      _userName = '$firstName $lastName';
      _role = role;

      // Fetch user data from Firestore to ensure consistency
      await _fetchUserData(id);

      // Save role in session storage — without this the userRole getter
      // treats the session as invalid and forces a logout after signup
      saveUserRole(_role);
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
      // 🔥 CRITICAL: Set persistence to SESSION (tab-specific)
      await FirebaseAuth.instance.setPersistence(Persistence.SESSION);

      final id = await _controller.login(email: e, password: p);
      uid = id;
      _userEmail = e;
      await _fetchUserData(id);

      // Save role in session storage
      saveUserRole(_role);

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

      // 🔥 Clear only this tab’s session
      clearSession();

      // Clear cached user data from SharedPreferences
      try {
        final prefs = SharedPrefsHelper();
        await prefs.clearUserData();

        // Clear cache service
        final cacheService = CacheService();
        cacheService.clearAllCache();
      } catch (e) {
        debugPrint('Error clearing caches during logout: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update user profile fields in Firestore and Firebase Auth displayName.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = currentUserId ?? uid;
    if (userId == null) throw Exception('No authenticated user');

    try {
      _loading = true;
      notifyListeners();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));

      final firstName = data['firstName'] as String?;
      final lastName = data['lastName'] as String?;
      if (firstName != null && firstName.isNotEmpty) {
        final displayName = (lastName != null && lastName.isNotEmpty)
            ? '$firstName $lastName'
            : firstName;
        await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
        _userName = displayName;
      }

      // Update cached email if provided
      if (data['email'] is String) {
        _userEmail = data['email'] as String;
      }

      notifyListeners();
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
