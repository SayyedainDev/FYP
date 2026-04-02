import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

class PatientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Patient> _patients = [];
  bool _loading = false;
  String? _error;

  List<Patient> get patients => List.unmodifiable(_patients);
  bool get loading => _loading;
  String? get error => _error;
  int get totalPatients => _patients.length;

  // Fetch patients from Firestore for a specific dentist
  Future<void> fetchPatients(String dentistUid) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore
          .collection('patients')
          .where('dentistUid', isEqualTo: dentistUid);

      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await query
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // Fallback without orderBy if index missing (web may need composite index)
        debugPrint('OrderBy failed, falling back without ordering: $e');
        querySnapshot = await query.get();
      }

      _patients = querySnapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      _patients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch patients: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching patients: $e');
    }
  }

  // Listen to real-time updates from Firestore for a specific dentist
  void listenToPatients(String dentistUid) {
    _firestore
        .collection('patients')
        .where('dentistUid', isEqualTo: dentistUid)
        .snapshots()
        .listen(
          (snapshot) {
            _patients = snapshot.docs
                .map((doc) => Patient.fromFirestore(doc))
                .toList();
            _patients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            notifyListeners();
          },
          onError: (e) {
            _error = 'Error listening to patients: $e';
            notifyListeners();
            debugPrint('Error listening to patients: $e');
          },
        );
  }

  // Add a new patient to Firestore and update user's patient list
  Future<String> addPatient(Patient patient, String dentistUid) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final newPatient = patient.copyWith(dentistUid: dentistUid);

      // Add patient to patients collection
      final patientDocRef = await _firestore
          .collection('patients')
          .add(newPatient.toFirestore());

      final patientId = patientDocRef.id;

      // Update user document to include this patient ID
      await _updateUserPatientsList(dentistUid, patientId, isAdd: true);

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchPatients(dentistUid);
      
      return patientId;
    } catch (e) {
      _error = 'Failed to add patient: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error adding patient: $e');
      rethrow;
    }
  }

  // Update user's patients array
  Future<void> _updateUserPatientsList(
    String dentistUid,
    String patientId, {
    required bool isAdd,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(dentistUid);

      if (isAdd) {
        // Add patient ID to user's patientIds array
        await userRef.update({
          'patientIds': FieldValue.arrayUnion([patientId]),
        });
      } else {
        // Remove patient ID from user's patientIds array
        await userRef.update({
          'patientIds': FieldValue.arrayRemove([patientId]),
        });
      }
    } catch (e) {
      // If patientIds field doesn't exist, create it
      if (isAdd) {
        await _firestore.collection('users').doc(dentistUid).set({
          'patientIds': [patientId],
        }, SetOptions(merge: true));
      }
      debugPrint('Updated user patients list: $e');
    }
  }

  // Update an existing patient
  Future<void> updatePatient(Patient patient, String dentistUid) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('patients')
          .doc(patient.id)
          .update(patient.toFirestore());

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchPatients(dentistUid);
    } catch (e) {
      _error = 'Failed to update patient: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error updating patient: $e');
      rethrow;
    }
  }

  // Delete a patient and remove from user's patient list
  Future<void> deletePatient(String patientId, String dentistUid) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Delete patient document
      await _firestore.collection('patients').doc(patientId).delete();

      // Remove patient ID from user's patientIds array
      await _updateUserPatientsList(dentistUid, patientId, isAdd: false);

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchPatients(dentistUid);
    } catch (e) {
      _error = 'Failed to delete patient: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error deleting patient: $e');
      rethrow;
    }
  }

  // Get a patient by ID
  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((patient) => patient.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get recent patients (limit to N)
  List<Patient> getRecentPatients({int limit = 3}) {
    return _patients.take(limit).toList();
  }

  // Get patient count for a specific dentist from Firestore user document
  Future<int> getPatientCountFromUser(String dentistUid) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(dentistUid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final patientIds = data['patientIds'] as List<dynamic>?;
        return patientIds?.length ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting patient count: $e');
      return 0;
    }
  }
}
