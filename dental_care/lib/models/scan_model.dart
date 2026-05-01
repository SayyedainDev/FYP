import 'package:flutter/material.dart';

class ScanModel {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime scanDate;
  final String scanType;
  final String? imageUrl;
  final int? imageWidth;
  final int? imageHeight;
  final String status; // 'uploaded' | 'analyzed' | 'prescribed'
  final int findingCount;
  final List<ScanFinding> findings;
  final PrescriptionModel? prescription;

  ScanModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.scanDate,
    required this.scanType,
    this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    required this.status,
    required this.findingCount,
    this.findings = const [],
    this.prescription,
  });

  bool get isHealthy => findingCount == 0 && status == 'analyzed';
  bool get hasPrescription => prescription != null || status == 'prescribed';

  Color get statusColor {
    switch (status) {
      case 'analyzed':
        return isHealthy ? const Color(0xFF166534) : const Color(0xFF1E40AF); // Green or Blue
      case 'prescribed':
        return const Color(0xFF5B21B6); // Purple
      case 'uploaded':
      default:
        return const Color(0xFF92400E); // Amber
    }
  }

  Color get statusBackgroundColor {
    switch (status) {
      case 'analyzed':
        return isHealthy ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
      case 'prescribed':
        return const Color(0xFFEDE9FE);
      case 'uploaded':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'analyzed':
        return 'Analyzed';
      case 'prescribed':
        return 'Prescribed';
      case 'uploaded':
      default:
        return 'Uploaded';
    }
  }

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    var findingsJson = json['scan_findings'] as List<dynamic>? ?? [];
    List<ScanFinding> findingsList = findingsJson.map((f) => ScanFinding.fromJson(f as Map<String, dynamic>)).toList();

    var rxJson = json['prescriptions'] as List<dynamic>? ?? [];
    PrescriptionModel? prescriptionModel;
    if (rxJson.isNotEmpty) {
      prescriptionModel = PrescriptionModel.fromJson(rxJson.first as Map<String, dynamic>);
    }

    return ScanModel(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      scanDate: DateTime.parse(json['scan_date']),
      scanType: json['scan_type'] ?? 'Panoramic OPG',
      imageUrl: json['image_url'],
      imageWidth: json['image_width'],
      imageHeight: json['image_height'],
      status: json['status'] ?? 'uploaded',
      findingCount: json['finding_count'] ?? 0,
      findings: findingsList,
      prescription: prescriptionModel,
    );
  }
}

class ScanFinding {
  final String id;
  final String scanId;
  final String label;
  final double confidence; // 0.0–1.0
  final int? boxX1;
  final int? boxY1;
  final int? boxX2;
  final int? boxY2;
  final String? colorHex;

  ScanFinding({
    required this.id,
    required this.scanId,
    required this.label,
    required this.confidence,
    this.boxX1,
    this.boxY1,
    this.boxX2,
    this.boxY2,
    this.colorHex,
  });

  factory ScanFinding.fromJson(Map<String, dynamic> json) {
    return ScanFinding(
      id: json['id'],
      scanId: json['scan_id'],
      label: json['label'],
      confidence: (json['confidence'] as num).toDouble(),
      boxX1: json['box_x1'],
      boxY1: json['box_y1'],
      boxX2: json['box_x2'],
      boxY2: json['box_y2'],
      colorHex: json['color_hex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scan_id': scanId,
      'label': label,
      'confidence': confidence,
      'box_x1': boxX1,
      'box_y1': boxY1,
      'box_x2': boxX2,
      'box_y2': boxY2,
      'color_hex': colorHex,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String scanId;
  final String patientId;
  final String patientName;
  final String diagnosis;
  final String prescription;
  final String followUp;
  final String precautions;
  final DateTime writtenAt;

  PrescriptionModel({
    required this.id,
    required this.scanId,
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.prescription,
    required this.followUp,
    required this.precautions,
    required this.writtenAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      scanId: json['scan_id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      diagnosis: json['diagnosis'],
      prescription: json['prescription'],
      followUp: json['follow_up'],
      precautions: json['precautions'],
      writtenAt: json['written_at'] != null ? DateTime.parse(json['written_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'scan_id': scanId,
      'patient_id': patientId,
      'patient_name': patientName,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'follow_up': followUp,
      'precautions': precautions,
    };
  }
}
