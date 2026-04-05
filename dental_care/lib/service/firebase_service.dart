// Firebase helper: auth, firestore, storage calls.
// Assumes firebase_core initialized in main.dart.
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final supabase = Supabase.instance.client;

  Future<fb.UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<fb.UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _fire.collection('users').doc(uid).set(data);

  Future<String> uploadImage(
    String uid,
    String fileName,
    List<int> bytes,
  ) async {
    final bucket = 'uploads';
    final path = '$uid/$fileName';
    await supabase.storage
        .from(bucket)
        .uploadBinary(path, Uint8List.fromList(bytes));
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  fb.User? get currentUser => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();
}
