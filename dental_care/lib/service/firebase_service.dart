// Firebase helper: auth, firestore, storage calls.
// Assumes firebase_core initialized in main.dart.
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final supabase = Supabase.instance.client;
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

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _fire.collection('users').doc(uid).set(data).timeout(_requestTimeout);

  Future<String> uploadImage(
    String uid,
    String fileName,
    List<int> bytes,
  ) async {
    const bucket = 'uploads';
    final path = '$uid/$fileName';
    await supabase.storage
        .from(bucket)
        .uploadBinary(path, Uint8List.fromList(bytes))
        .timeout(_requestTimeout);
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  fb.User? get currentUser => _auth.currentUser;
  bool get isCurrentUserEmailVerified =>
      _auth.currentUser?.emailVerified ?? false;
  Future<void> signOut() => _auth.signOut().timeout(_requestTimeout);
}
