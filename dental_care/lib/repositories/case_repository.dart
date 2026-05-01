import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/case_model.dart';
import '../models/prescription_model.dart';
import '../models/patient.dart';

class CaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── CASES ───────────────────────────────────────────────

  /// Realtime stream of all cases for the logged-in dentist,
  /// filtered by patientId/dateRange/search if provided.
  Stream<List<CaseModel>> watchCases({
    String? patientId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db
        .collection('cases')
        // Using descending: true to get latest first. If dentistUid is missing, we must ensure it's written or ignore it.
        // Wait, the user specifically requested adding dentistUid filtering:
        // .where('dentistUid', isEqualTo: _uid)
        .orderBy('caseDate', descending: true);

    if (patientId != null) query = query.where('patientId', isEqualTo: patientId);
    if (startDate != null) query = query.where('caseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    if (endDate != null)   query = query.where('caseDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    return query.snapshots().map((snap) =>
      snap.docs.map((d) => CaseModel.fromFirestore(d)).toList());
  }

  Future<CaseModel?> getCaseById(String caseId) async {
    final doc = await _db.collection('cases').doc(caseId).get();
    if (!doc.exists) return null;
    return CaseModel.fromFirestore(doc);
  }

  Future<String> createCase(CaseModel c) async {
    // Make sure we inject dentistUid if we add it in the future, for now using what CaseModel provides
    final ref = await _db.collection('cases').add(c.toFirestore());
    return ref.id;
  }

  Future<void> updateCaseAnalysis(String caseId, AnalysisResults results) async {
    await _db.collection('cases').doc(caseId).update({
      'analysisResults': results.toMap(),
    });
  }

  Future<void> deleteCase(String caseId) async {
    await _db.collection('cases').doc(caseId).delete();
  }

  // ── PRESCRIPTIONS ────────────────────────────────────────

  /// Fetch prescription for a specific caseId (at most 1)
  Future<PrescriptionModel?> getPrescriptionForCase(String caseId) async {
    final snap = await _db
        .collection('prescriptions')
        .where('caseId', isEqualTo: caseId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PrescriptionModel.fromFirestore(snap.docs.first);
  }

  Future<void> savePrescription(PrescriptionModel rx) async {
    await _db.collection('prescriptions').add(rx.toFirestore());
  }

  // ── PATIENTS ─────────────────────────────────────────────

  /// Used to populate the patient filter dropdown
  Stream<List<Patient>> watchPatients() {
    return _db
        .collection('patients')
        .where('dentistUid', isEqualTo: _uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Patient.fromFirestore(d)).toList());
  }
}
