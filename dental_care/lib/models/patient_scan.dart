import 'package:cloud_firestore/cloud_firestore.dart';

class PatientScan {
  final String scanId;
  final String imageUrl; // Supabase public URL
  final DateTime timestamp;
  final String notes;
  final List<Map<String, dynamic>> detections;
  final String dentistUid;
  final String patientId;

  PatientScan({
    required this.scanId,
    required this.imageUrl,
    required this.timestamp,
    required this.notes,
    required this.detections,
    required this.dentistUid,
    required this.patientId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'scanId': scanId,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'detections': detections,
      'dentistUid': dentistUid,
      'patientId': patientId,
    };
  }

  factory PatientScan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientScan(
      scanId: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      notes: data['notes'] ?? '',
      detections: List<Map<String, dynamic>>.from(data['detections'] ?? []),
      dentistUid: data['dentistUid'] ?? '',
      patientId: data['patientId'] ?? '',
    );
  }
}
