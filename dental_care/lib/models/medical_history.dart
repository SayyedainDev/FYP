import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalHistory {
  final String id;
  final String patientId;
  final List<String> allergies; // Drug allergies, material allergies
  final List<String> medicalConditions; // Diabetes, hypertension, etc.
  final List<String> currentMedications;
  final List<String> previousTreatments; // Previous dental treatments
  final List<SurgicalHistory> surgicalHistory;
  final bool smoker;
  final bool alcoholConsumer;
  final String bloodType;
  final String? familyHistory;
  final DateTime lastUpdated;

  MedicalHistory({
    required this.id,
    required this.patientId,
    required this.allergies,
    required this.medicalConditions,
    required this.currentMedications,
    required this.previousTreatments,
    required this.surgicalHistory,
    required this.smoker,
    required this.alcoholConsumer,
    required this.bloodType,
    this.familyHistory,
    required this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'currentMedications': currentMedications,
      'previousTreatments': previousTreatments,
      'surgicalHistory': surgicalHistory.map((s) => s.toMap()).toList(),
      'smoker': smoker,
      'alcoholConsumer': alcoholConsumer,
      'bloodType': bloodType,
      'familyHistory': familyHistory,
      'lastUpdated': lastUpdated,
    };
  }

  static MedicalHistory fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalHistory(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      currentMedications: List<String>.from(data['currentMedications'] ?? []),
      previousTreatments: List<String>.from(data['previousTreatments'] ?? []),
      surgicalHistory: (data['surgicalHistory'] as List<dynamic>?)
              ?.map((s) => SurgicalHistory.fromMap(s))
              .toList() ??
          [],
      smoker: data['smoker'] ?? false,
      alcoholConsumer: data['alcoholConsumer'] ?? false,
      bloodType: data['bloodType'] ?? 'Unknown',
      familyHistory: data['familyHistory'],
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}

class SurgicalHistory {
  final String procedure;
  final DateTime date;
  final String? notes;

  SurgicalHistory({required this.procedure, required this.date, this.notes});

  Map<String, dynamic> toMap() {
    return {'procedure': procedure, 'date': date, 'notes': notes};
  }

  static SurgicalHistory fromMap(Map<String, dynamic> map) {
    return SurgicalHistory(
      procedure: map['procedure'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
    );
  }
}
