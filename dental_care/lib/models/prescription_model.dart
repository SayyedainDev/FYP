import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionModel {
  final String id;
  final String patientId;
  final String caseId;
  final String dentistUid;
  final String dentistName;
  final String diagnosis;
  final String prescription;
  final String followUpTreatment;
  final String precautions;
  final DateTime createdAt;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.caseId,
    required this.dentistUid,
    required this.dentistName,
    required this.diagnosis,
    required this.prescription,
    required this.followUpTreatment,
    required this.precautions,
    required this.createdAt,
  });

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PrescriptionModel(
      id: doc.id,
      patientId: d['patientId'] ?? '',
      caseId: d['caseId'] ?? '',
      dentistUid: d['dentistUid'] ?? '',
      dentistName: d['dentistName'] ?? '',
      diagnosis: d['diagnosis'] ?? '',
      prescription: d['prescription'] ?? '',
      followUpTreatment: d['followUpTreatment'] ?? '',
      precautions: d['precautions'] ?? '',
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'patientId': patientId,
    'caseId': caseId,
    'dentistUid': dentistUid,
    'dentistName': dentistName,
    'diagnosis': diagnosis,
    'prescription': prescription,
    'followUpTreatment': followUpTreatment,
    'precautions': precautions,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
