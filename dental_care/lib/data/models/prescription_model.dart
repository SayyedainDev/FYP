class MedicationItem {
  final String name;
  final String dose;
  final String frequency;
  final String duration;

  MedicationItem({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dose': dose,
    'frequency': frequency,
    'duration': duration,
  };

  factory MedicationItem.fromJson(Map<String, dynamic> json) =>
      MedicationItem(
        name: json['name'] ?? '',
        dose: json['dose'] ?? '',
        frequency: json['frequency'] ?? '',
        duration: json['duration'] ?? '',
      );
}

class PrescriptionModel {
  final String id;
  final DateTime createdAt;
  final String patientId;
  final String? detectionId;
  final String diagnosis;
  final List<MedicationItem> medications;
  final String? instructions;
  final DateTime? followUpDate;
  final bool isFinalized;

  PrescriptionModel({
    required this.id,
    required this.createdAt,
    required this.patientId,
    this.detectionId,
    required this.diagnosis,
    required this.medications,
    this.instructions,
    this.followUpDate,
    this.isFinalized = false,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      patientId: json['patient_id'],
      detectionId: json['detection_id'],
      diagnosis: json['diagnosis'] ?? '',
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((m) => MedicationItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      instructions: json['instructions'],
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'])
          : null,
      isFinalized: json['is_finalized'] ?? false,
    );
  }
}
