// Firebase helper: auth, firestore, storage calls.
// Assumes firebase_core initialized in main.dart.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// Supabase removed

class FirebaseService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  // Supabase removed — use Firebase Storage implementations instead when needed
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
      final storage = FirebaseStorage.instance;
      final path = 'users/$uid/$fileName';
      final ref = storage.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/png');
      final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase uploadImage error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String uid, String fileName) async {
    try {
      final storage = FirebaseStorage.instance;
      final path = 'users/$uid/$fileName';
      final ref = storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      debugPrint('Firebase deleteFile error: $e');
      rethrow;
    }
  }

  fb.User? get currentUser => _auth.currentUser;
  bool get isCurrentUserEmailVerified =>
      _auth.currentUser?.emailVerified ?? false;
  Future<void> signOut() => _auth.signOut().timeout(_requestTimeout);
}
