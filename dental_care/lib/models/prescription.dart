import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String dentistUid;
  final String dentistName;
  final String patientId;
  final String patientName;
  final String patientPhone; // For WhatsApp sharing
  final String caseId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String diagnosis;
  final String prescription;
  final String followUpTreatment;
  final String precautions;
  final bool isShared; // Track if shared via WhatsApp
  final DateTime? sharedAt; // Track sharing timestamp
  final String status; // 'Active' | 'Completed' | 'Archived'

  Prescription({
    required this.id,
    required this.dentistUid,
    required this.dentistName,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.caseId,
    required this.createdAt,
    required this.diagnosis,
    required this.prescription,
    required this.followUpTreatment,
    required this.precautions,
    this.updatedAt,
    this.isShared = false,
    this.sharedAt,
    this.status = 'Active',
  });

  // Convert Prescription to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'dentistUid': dentistUid,
      'dentistName': dentistName,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'caseId': caseId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? createdAt),
      'diagnosis': diagnosis,
      'prescription': prescription,
      'followUpTreatment': followUpTreatment,
      'precautions': precautions,
      'isShared': isShared,
      'sharedAt': sharedAt != null ? Timestamp.fromDate(sharedAt!) : null,
      'status': status,
    };
  }

  // Create Prescription from Firestore DocumentSnapshot
  factory Prescription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prescription(
      id: doc.id,
      dentistUid: data['dentistUid'] ?? '',
      dentistName: data['dentistName'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      caseId: data['caseId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      diagnosis: data['diagnosis'] ?? '',
      prescription: data['prescription'] ?? '',
      followUpTreatment: data['followUpTreatment'] ?? '',
      precautions: data['precautions'] ?? '',
      isShared: data['isShared'] ?? false,
      sharedAt: (data['sharedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'Active',
    );
  }

  // Copy with method for updates
  Prescription copyWith({
    String? id,
    String? dentistUid,
    String? dentistName,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? caseId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? diagnosis,
    String? prescription,
    String? followUpTreatment,
    String? precautions,
    bool? isShared,
    DateTime? sharedAt,
    String? status,
  }) {
    return Prescription(
      id: id ?? this.id,
      dentistUid: dentistUid ?? this.dentistUid,
      dentistName: dentistName ?? this.dentistName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      caseId: caseId ?? this.caseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      followUpTreatment: followUpTreatment ?? this.followUpTreatment,
      precautions: precautions ?? this.precautions,
      isShared: isShared ?? this.isShared,
      sharedAt: sharedAt ?? this.sharedAt,
      status: status ?? this.status,
    );
  }

  // Format prescription for WhatsApp sharing
  String toWhatsAppMessage() {
    return '''
📋 *Prescription for $patientName*

*From:* Dr. $dentistName

*Diagnosis:*
$diagnosis

*Prescription:*
$prescription

*Follow-Up Treatment:*
$followUpTreatment

*Precautions:*
$precautions

Created on: ${createdAt.toString().split('.')[0]}
''';
  }
}
