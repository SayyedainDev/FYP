import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/treatment_plan.dart';

class TreatmentPlanProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<TreatmentPlan> _treatmentPlans = [];
  bool _loading = false;
  String? _error;

  List<TreatmentPlan> get treatmentPlans => List.unmodifiable(_treatmentPlans);
  bool get loading => _loading;
  String? get error => _error;

  List<TreatmentPlan> get activePlans {
    return _treatmentPlans.where((p) => p.status == 'active').toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  List<TreatmentPlan> getPatientPlans(String patientId) {
    return _treatmentPlans.where((p) => p.patientId == patientId).toList();
  }

  double getTotalCost(String patientId) {
    return _treatmentPlans
        .where((p) => p.patientId == patientId)
        .fold(0.0, (sum, plan) => sum + plan.estimatedCost);
  }

  Future<void> fetchTreatmentPlans(String dentistUid) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('treatment_plans')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('startDate', descending: true)
          .get();

      _treatmentPlans = querySnapshot.docs
          .map((doc) => TreatmentPlan.fromFirestore(doc))
          .toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch treatment plans: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching treatment plans: $e');
    }
  }

  Future<void> createTreatmentPlan(TreatmentPlan plan) async {
    try {
      _loading = true;
      notifyListeners();

      await _firestore
          .collection('treatment_plans')
          .doc(plan.id)
          .set(plan.toFirestore());

      _treatmentPlans.add(plan);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create treatment plan: $e';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateTreatmentPlan(TreatmentPlan plan) async {
    try {
      await _firestore
          .collection('treatment_plans')
          .doc(plan.id)
          .update(plan.toFirestore());

      final index = _treatmentPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _treatmentPlans[index] = plan;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update treatment plan: $e';
      notifyListeners();
    }
  }

  Future<void> updateProgress(String planId, int progress) async {
    try {
      await _firestore.collection('treatment_plans').doc(planId).update({
        'progressPercentage': progress,
        'updatedAt': DateTime.now(),
      });

      final index = _treatmentPlans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        final updated = _treatmentPlans[index];
        _treatmentPlans[index] = TreatmentPlan(
          id: updated.id,
          patientId: updated.patientId,
          dentistUid: updated.dentistUid,
          title: updated.title,
          description: updated.description,
          phases: updated.phases,
          status: updated.status,
          startDate: updated.startDate,
          completionDate: updated.completionDate,
          estimatedCost: updated.estimatedCost,
          priority: updated.priority,
          progressPercentage: progress,
          createdAt: updated.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update progress: $e';
      notifyListeners();
    }
  }
}
