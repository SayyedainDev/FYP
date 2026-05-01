import 'dart:convert';

class DetectionRecord {
  final String id;
  final DateTime createdAt;
  final String patientId;
  final String? performedBy;
  final String? originalImagePath;
  final String? annotatedImagePath;
  final Map<String, dynamic> rawResponse;
  final List<String> conditionsFound;
  final int totalDetections;
  final double highestConfidence;
  final String? notes;

  DetectionRecord({
    required this.id,
    required this.createdAt,
    required this.patientId,
    this.performedBy,
    this.originalImagePath,
    this.annotatedImagePath,
    required this.rawResponse,
    required this.conditionsFound,
    required this.totalDetections,
    required this.highestConfidence,
    this.notes,
  });

  /// Full URLs for images
  String? get originalImageUrl => originalImagePath;
  String? get annotatedImageUrl => annotatedImagePath;

  factory DetectionRecord.fromJson(Map<String, dynamic> json) {
    return DetectionRecord(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      patientId: json['patient_id'],
      performedBy: json['performed_by'],
      originalImagePath: json['original_image_path'],
      annotatedImagePath: json['annotated_image_path'],
      rawResponse: json['raw_response'] is String
          ? jsonDecode(json['raw_response'])
          : Map<String, dynamic>.from(json['raw_response']),
      conditionsFound: List<String>.from(json['conditions_found'] ?? []),
      totalDetections: json['total_detections'] ?? 0,
      highestConfidence: (json['highest_confidence'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }
}
