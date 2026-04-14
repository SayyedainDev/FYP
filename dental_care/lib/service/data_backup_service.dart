import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class DataBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Create full backup of all user data
  Future<Map<String, dynamic>> createFullBackup(String userId) async {
    try {
      final backup = <String, dynamic>{
        'backupDate': DateTime.now(),
        'userId': userId,
        'data': <String, dynamic>{},
      };

      // Backup patients
      final patientsSnapshot = await _firestore
          .collection('patients')
          .where('dentistUid', isEqualTo: userId)
          .get()
          .timeout(_requestTimeout);

      backup['data']['patients'] =
          patientsSnapshot.docs.map((doc) => doc.data()).toList();

      // Backup cases
      final casesSnapshot = await _firestore
          .collection('cases')
          .where('dentistUid', isEqualTo: userId)
          .get()
          .timeout(_requestTimeout);

      backup['data']['cases'] =
          casesSnapshot.docs.map((doc) => doc.data()).toList();

      // Backup appointments
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('dentistUid', isEqualTo: userId)
          .get()
          .timeout(_requestTimeout);

      backup['data']['appointments'] =
          appointmentsSnapshot.docs.map((doc) => doc.data()).toList();

      // Backup treatment plans
      final treatmentPlansSnapshot = await _firestore
          .collection('treatment_plans')
          .where('dentistUid', isEqualTo: userId)
          .get()
          .timeout(_requestTimeout);

      backup['data']['treatmentPlans'] =
          treatmentPlansSnapshot.docs.map((doc) => doc.data()).toList();

      // Store backup metadata
      await _firestore
          .collection('backups')
          .doc('${userId}_${DateTime.now().millisecondsSinceEpoch}')
          .set(backup)
          .timeout(_requestTimeout);

      return backup;
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of all backups for a user
  Future<List<Map<String, dynamic>>> getBackupHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('backups')
          .where('userId', isEqualTo: userId)
          .orderBy('backupDate', descending: true)
          .get()
          .timeout(_requestTimeout);

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Export user data as JSON
  Future<String> exportAsJson(String userId) async {
    try {
      final backup = await createFullBackup(userId);
      return _convertToJson(backup);
    } catch (e) {
      rethrow;
    }
  }

  /// Restore data from backup
  Future<void> restoreFromBackup(
    String userId,
    Map<String, dynamic> backup,
  ) async {
    try {
      final data = backup['data'] as Map<String, dynamic>;

      // Restore patients
      if (data['patients'] != null) {
        for (var patient in data['patients']) {
          await _firestore
              .collection('patients')
              .add(patient)
              .timeout(_requestTimeout);
        }
      }

      // Restore cases
      if (data['cases'] != null) {
        for (var case_ in data['cases']) {
          await _firestore
              .collection('cases')
              .add(case_)
              .timeout(_requestTimeout);
        }
      }

      // Restore appointments
      if (data['appointments'] != null) {
        for (var appointment in data['appointments']) {
          await _firestore
              .collection('appointments')
              .add(appointment)
              .timeout(_requestTimeout);
        }
      }

      // Restore treatment plans
      if (data['treatmentPlans'] != null) {
        for (var plan in data['treatmentPlans']) {
          await _firestore
              .collection('treatment_plans')
              .add(plan)
              .timeout(_requestTimeout);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  String _convertToJson(Map<String, dynamic> data) {
    return data.toString(); // Implement proper JSON serialization
  }
}
