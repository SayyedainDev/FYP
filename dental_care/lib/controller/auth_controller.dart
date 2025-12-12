// Controller: handles logic for login/register using FirebaseService.
// Keep UI-free: returns results or throws exceptions for the view to show.

import '../service/firebase_service.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseService _service;
  AuthController(this._service);

  Future<String> register({
    required String email,
    required String password,
    required String userId,
    required String firstName,
    required String lastName,
    required String cnic,
    required String address,
    required String highestEducation,
  }) async {
    final cred = await _service.signUpWithEmail(email, password);
    final uid = cred.user!.uid;
    final user = UserModel(
      uid: uid,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      cnic: cnic,
      address: address,
      highestEducation: highestEducation,
      email: email,
    );
    await _service.saveUserProfile(uid, user.toMap());
    return uid;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final cred = await _service.signInWithEmail(email, password);
    return cred.user!.uid;
  }

  Future<void> logout() async {
    await _service.signOut();
  }
}
