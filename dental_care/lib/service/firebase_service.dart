// Firebase helper: auth, firestore, storage calls.
// Assumes firebase_core initialized in main.dart.
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _fire.collection('users').doc(uid).set(data);

  Future<String> uploadImage(
    String uid,
    String fileName,
    List<int> bytes,
  ) async {
    final ref = _storage.ref().child('uploads/$uid/$fileName');
    final task = await ref.putData(Uint8List.fromList(bytes));
    return task.ref.getDownloadURL();
  }

  User? get currentUser => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();
}
