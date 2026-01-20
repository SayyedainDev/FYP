import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_history.dart';

class MedicalHistoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, MedicalHistory> _histories = {};
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  MedicalHistory? getPatientHistory(String patientId) {
    return _histories[patientId];
  }

  Future<void> fetchMedicalHistory(String patientId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final doc = await _firestore
          .collection('medical_history')
          .doc(patientId)
          .get();

      if (doc.exists) {
        _histories[patientId] = MedicalHistory.fromFirestore(doc);
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch medical history: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching medical history: $e');
    }
  }

  Future<void> createOrUpdateMedicalHistory(MedicalHistory history) async {
    try {
      _loading = true;
      notifyListeners();

      await _firestore
          .collection('medical_history')
          .doc(history.patientId)
          .set(history.toFirestore(), SetOptions(merge: true));

      _histories[history.patientId] = history;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save medical history: $e';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addAllergy(String patientId, String allergy) async {
    try {
      await _firestore.collection('medical_history').doc(patientId).update({
        'allergies': FieldValue.arrayUnion([allergy]),
      });

      final history = _histories[patientId];
      if (history != null) {
        _histories[patientId] = MedicalHistory(
          id: history.id,
          patientId: history.patientId,
          allergies: [...history.allergies, allergy],
          medicalConditions: history.medicalConditions,
          currentMedications: history.currentMedications,
          previousTreatments: history.previousTreatments,
          surgicalHistory: history.surgicalHistory,
          smoker: history.smoker,
          alcoholConsumer: history.alcoholConsumer,
          bloodType: history.bloodType,
          familyHistory: history.familyHistory,
          lastUpdated: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add allergy: $e';
      notifyListeners();
    }
  }

  Future<void> removeAllergy(String patientId, String allergy) async {
    try {
      await _firestore.collection('medical_history').doc(patientId).update({
        'allergies': FieldValue.arrayRemove([allergy]),
      });

      final history = _histories[patientId];
      if (history != null) {
        _histories[patientId] = MedicalHistory(
          id: history.id,
          patientId: history.patientId,
          allergies: history.allergies.where((a) => a != allergy).toList(),
          medicalConditions: history.medicalConditions,
          currentMedications: history.currentMedications,
          previousTreatments: history.previousTreatments,
          surgicalHistory: history.surgicalHistory,
          smoker: history.smoker,
          alcoholConsumer: history.alcoholConsumer,
          bloodType: history.bloodType,
          familyHistory: history.familyHistory,
          lastUpdated: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to remove allergy: $e';
      notifyListeners();
    }
  }
}
