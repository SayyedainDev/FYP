import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String dentistUid;
  final DateTime appointmentDate;
  final Duration duration; // Duration of appointment
  final String status; // 'scheduled', 'completed', 'cancelled', 'no-show'
  final String
  appointmentType; // 'consultation', 'treatment', 'follow-up', 'checkup'
  final String notes;
  final String? location; // Clinic location
  final bool reminderSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.dentistUid,
    required this.appointmentDate,
    required this.duration,
    required this.status,
    required this.appointmentType,
    required this.notes,
    this.location,
    required this.reminderSent,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'dentistUid': dentistUid,
      'appointmentDate': appointmentDate,
      'durationMinutes': duration.inMinutes,
      'status': status,
      'appointmentType': appointmentType,
      'notes': notes,
      'location': location,
      'reminderSent': reminderSent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Convert from Firestore
  static Appointment fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      dentistUid: data['dentistUid'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      duration: Duration(minutes: data['durationMinutes'] ?? 30),
      status: data['status'] ?? 'scheduled',
      appointmentType: data['appointmentType'] ?? 'consultation',
      notes: data['notes'] ?? '',
      location: data['location'],
      reminderSent: data['reminderSent'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Appointment copyWith({String? status, String? notes, bool? reminderSent}) {
    return Appointment(
      id: id,
      patientId: patientId,
      dentistUid: dentistUid,
      appointmentDate: appointmentDate,
      duration: duration,
      status: status ?? this.status,
      appointmentType: appointmentType,
      notes: notes ?? this.notes,
      location: location,
      reminderSent: reminderSent ?? this.reminderSent,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
