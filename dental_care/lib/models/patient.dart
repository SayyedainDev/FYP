import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String dentistUid;
  final String name;
  final DateTime dob;
  final String gender;
  final String contactPhone;
  final String contactEmail;
  final String notes;
  final DateTime createdAt;
  final String healthStatus; // Healthy, Critical, At Risk, etc.

  Patient({
    required this.id,
    required this.dentistUid,
    required this.name,
    required this.dob,
    required this.gender,
    required this.contactPhone,
    required this.contactEmail,
    required this.notes,
    required this.createdAt,
    this.healthStatus = 'Healthy',
  });

  // Calculate age from date of birth
  int get age {
    final now = DateTime.now();
    int calculatedAge = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  // Get color for health status
  static const Map<String, int> statusColors = {
    'Healthy': 0xFF4CAF50, // Green
    'At Risk': 0xFFFFC107, // Amber
    'Critical': 0xFFF44336, // Red
    'Pending': 0xFF2196F3, // Blue
  };

  // Convert Patient to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'dentistUid': dentistUid,
      'name': name,
      'dob': Timestamp.fromDate(dob),
      'gender': gender,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'healthStatus': healthStatus,
    };
  }

  // Create Patient from Firestore DocumentSnapshot
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient(
      id: doc.id,
      dentistUid: data['dentistUid'] ?? '',
      name: data['name'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      healthStatus: data['healthStatus'] ?? 'Healthy',
    );
  }

  // Get initials from name
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Copy with method for updates
  Patient copyWith({
    String? id,
    String? dentistUid,
    String? name,
    DateTime? dob,
    String? gender,
    String? contactPhone,
    String? contactEmail,
    String? notes,
    DateTime? createdAt,
    String? healthStatus,
  }) {
    return Patient(
      id: id ?? this.id,
      dentistUid: dentistUid ?? this.dentistUid,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      healthStatus: healthStatus ?? this.healthStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dentistUid == other.dentistUid &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ dentistUid.hashCode ^ name.hashCode;
}
