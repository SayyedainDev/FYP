// Firebase helper: auth, firestore, storage calls.
// Assumes firebase_core initialized in main.dart.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/core/config/supabase_config.dart';


class FirebaseService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<fb.UserCredential> signUpWithEmail(String email, String password) =>
      _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_requestTimeout);

  Future<fb.UserCredential> signInWithEmail(String email, String password) =>
      _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_requestTimeout);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email).timeout(_requestTimeout);

  Future<void> sendCurrentUserEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }
    await user.sendEmailVerification().timeout(_requestTimeout);
  }

  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload().timeout(_requestTimeout);
  }

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _fire.collection('users').doc(uid).set(data).timeout(_requestTimeout);
    // Also set the displayName in Firebase Auth
    final firstName = data['firstName'] as String?;
    final lastName = data['lastName'] as String?;
    if (firstName != null && firstName.isNotEmpty) {
      final displayName = lastName != null && lastName.isNotEmpty
          ? '$firstName $lastName'
          : firstName;
      await _auth.currentUser
          ?.updateDisplayName(displayName)
          .timeout(_requestTimeout);
    }
  }

  Future<String> uploadImage(
    String uid,
    String fileName,
    List<int> bytes,
  ) async {
    try {
      final path = 'users/$uid/$fileName';
      await SupabaseConfig.client.storage.from('Image').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
          );
      final downloadUrl =
          SupabaseConfig.client.storage.from('Image').getPublicUrl(path);
      return downloadUrl;
    } catch (e) {
      debugPrint('Supabase uploadImage error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String uid, String fileName) async {
    try {
      final path = 'users/$uid/$fileName';
      await SupabaseConfig.client.storage.from('Image').remove([path]);
    } catch (e) {
      debugPrint('Supabase deleteFile error: $e');
      rethrow;
    }
  }

  fb.User? get currentUser => _auth.currentUser;
  bool get isCurrentUserEmailVerified =>
      _auth.currentUser?.emailVerified ?? false;
  Future<void> signOut() => _auth.signOut().timeout(_requestTimeout);
}
