import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/prescription.dart';

class PrescriptionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch prescriptions for a specific dentist
  Future<void> fetchPrescriptionsByDentist(String dentistUid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final query = await _firestore
          .collection('prescriptions')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('createdAt', descending: true)
          .get();

      _prescriptions =
          query.docs.map((doc) => Prescription.fromFirestore(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching prescriptions: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching prescriptions: $e');
    }
  }

  // Fetch prescriptions for a specific patient
  Future<List<Prescription>> fetchPatientPrescriptions(String patientId) async {
    try {
      final query = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Prescription.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching patient prescriptions: $e');
      return [];
    }
  }

  // Fetch prescriptions for a specific case
  Future<List<Prescription>> fetchCasePrescriptions(String caseId) async {
    try {
      final query = await _firestore
          .collection('prescriptions')
          .where('caseId', isEqualTo: caseId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Prescription.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching case prescriptions: $e');
      return [];
    }
  }

  // Create new prescription
  Future<Prescription?> createPrescription({
    required String dentistUid,
    required String dentistName,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String caseId,
    required String diagnosis,
    required String prescription,
    required String followUpTreatment,
    required String precautions,
  }) async {
    try {
      if (dentistUid.isEmpty || patientId.isEmpty) {
        throw Exception(
            'Missing required IDs: dentist=$dentistUid, patient=$patientId');
      }

      _isLoading = true;
      notifyListeners();

      final newPrescription = Prescription(
        id: '', // Will be set by Firestore
        dentistUid: dentistUid,
        dentistName: dentistName,
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        caseId:
            caseId, // may be empty when creating prescription without saved case
        createdAt: DateTime.now(),
        diagnosis: diagnosis,
        prescription: prescription,
        followUpTreatment: followUpTreatment,
        precautions: precautions,
      );

      debugPrint('💾 Saving prescription: ${newPrescription.toFirestore()}');

      final docRef = await _firestore
          .collection('prescriptions')
          .add(newPrescription.toFirestore());

      final createdPrescription = newPrescription.copyWith(id: docRef.id);

      _isLoading = false;
      notifyListeners();

      // Refresh prescriptions list (errors here won't block the save)
      try {
        await fetchPrescriptionsByDentist(dentistUid);
      } catch (e) {
        debugPrint('⚠️ Warning: Could not refresh prescriptions list: $e');
      }

      debugPrint('✅ Prescription saved with ID: ${docRef.id}');
      return createdPrescription;
    } catch (e) {
      _errorMessage = 'Error creating prescription: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Error creating prescription: $e');
      return null;
    }
  }

  // Update prescription
  Future<bool> updatePrescription(
    String prescriptionId, {
    required String diagnosis,
    required String prescription,
    required String followUpTreatment,
    required String precautions,
    required String status,
  }) async {
    try {
      await _firestore.collection('prescriptions').doc(prescriptionId).update({
        'diagnosis': diagnosis,
        'prescription': prescription,
        'followUpTreatment': followUpTreatment,
        'precautions': precautions,
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // Refresh the list
      final prescriptionIndex =
          _prescriptions.indexWhere((p) => p.id == prescriptionId);
      if (prescriptionIndex != -1) {
        _prescriptions[prescriptionIndex] =
            _prescriptions[prescriptionIndex].copyWith(
          diagnosis: diagnosis,
          prescription: prescription,
          followUpTreatment: followUpTreatment,
          precautions: precautions,
          status: status,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating prescription: $e');
      return false;
    }
  }

  // Mark prescription as shared via WhatsApp
  Future<bool> markAsShared(String prescriptionId) async {
    try {
      await _firestore.collection('prescriptions').doc(prescriptionId).update({
        'isShared': true,
        'sharedAt': Timestamp.now(),
      });

      final prescriptionIndex =
          _prescriptions.indexWhere((p) => p.id == prescriptionId);
      if (prescriptionIndex != -1) {
        _prescriptions[prescriptionIndex] =
            _prescriptions[prescriptionIndex].copyWith(
          isShared: true,
          sharedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error marking prescription as shared: $e');
      return false;
    }
  }

  // Delete prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      await _firestore.collection('prescriptions').doc(prescriptionId).delete();

      _prescriptions.removeWhere((p) => p.id == prescriptionId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting prescription: $e');
      return false;
    }
  }

  // Archive prescription
  Future<bool> archivePrescription(String prescriptionId) async {
    try {
      await _firestore.collection('prescriptions').doc(prescriptionId).update({
        'status': 'Archived',
        'updatedAt': Timestamp.now(),
      });

      final prescriptionIndex =
          _prescriptions.indexWhere((p) => p.id == prescriptionId);
      if (prescriptionIndex != -1) {
        _prescriptions[prescriptionIndex] =
            _prescriptions[prescriptionIndex].copyWith(
          status: 'Archived',
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error archiving prescription: $e');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
