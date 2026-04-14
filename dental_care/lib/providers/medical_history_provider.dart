import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_history.dart';
import '../utils/provider_error_utils.dart';

class MedicalHistoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, MedicalHistory> _histories = {};
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
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      if (doc.exists) {
        _histories[patientId] = MedicalHistory.fromFirestore(doc);
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to fetch medical history. Please try again.',
      );
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
          .set(history.toFirestore(), SetOptions(merge: true))
          .timeout(ProviderErrorUtils.requestTimeout);

      _histories[history.patientId] = history;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to save medical history. Please try again.',
      );
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addAllergy(String patientId, String allergy) async {
    try {
      await _firestore.collection('medical_history').doc(patientId).update({
        'allergies': FieldValue.arrayUnion([allergy]),
      }).timeout(ProviderErrorUtils.requestTimeout);

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
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to add allergy. Please try again.',
      );
      notifyListeners();
    }
  }

  Future<void> removeAllergy(String patientId, String allergy) async {
    try {
      await _firestore.collection('medical_history').doc(patientId).update({
        'allergies': FieldValue.arrayRemove([allergy]),
      }).timeout(ProviderErrorUtils.requestTimeout);

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
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to remove allergy. Please try again.',
      );
      notifyListeners();
    }
  }
}
