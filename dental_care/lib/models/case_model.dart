import 'package:cloud_firestore/cloud_firestore.dart';
import 'prescription_model.dart';

class CaseModel {
  final String id;
  final String patientId;
  final String patientName;
  final List<String> imageUrls;
  final AnalysisResults analysisResults;
  final DateTime caseDate;
  PrescriptionModel? prescription; // joined after fetch

  CaseModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.imageUrls,
    required this.analysisResults,
    required this.caseDate,
    this.prescription,
  });

  // Helpers
  bool get hasImages => imageUrls.isNotEmpty;
  bool get isAnalyzed => analysisResults.status == 'Analyzed';
  bool get hasPrescription => prescription != null;

  /// Overall display status for the UI badge
  String get displayStatus {
    if (hasPrescription) return 'Prescribed';
    if (analysisResults.status == 'Healthy' ||
        analysisResults.status == 'Cavity' ||
        analysisResults.status == 'Disease Detected') {
      return analysisResults.status;
    }
    if (isAnalyzed) {
      return analysisResults.hasCavity ? 'Cavity' : 'Healthy';
    }
    return 'Uploaded';
  }

  factory CaseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return CaseModel(
      id: doc.id,
      patientId: d['patientId'] ?? '',
      patientName: d['patientName'] ?? '',
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
      analysisResults: AnalysisResults.fromMap(d['analysisResults'] ?? {}),
      caseDate: d['caseDate'] != null
          ? (d['caseDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'imageUrls': imageUrls,
        'analysisResults': analysisResults.toMap(),
        'caseDate': Timestamp.fromDate(caseDate),
      };
}

class AnalysisResults {
  final String status;
  final bool hasCavity;
  final double confidence;
  final String
      details; // raw string, e.g. "Impacted tooth, root canal, filling"

  AnalysisResults({
    required this.status,
    required this.hasCavity,
    required this.confidence,
    required this.details,
  });

  /// Parse details string into a structured list
  List<String> get findingsList => details
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory AnalysisResults.fromMap(Map<String, dynamic>? m) {
    m ??= {};
    return AnalysisResults(
      status: m['status'] ?? 'Uploaded',
      hasCavity: m['hasCavity'] ?? false,
      confidence: (m['confidence'] ?? 0.0).toDouble(),
      details: m['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status,
        'hasCavity': hasCavity,
        'confidence': confidence,
        'details': details,
      };
}
