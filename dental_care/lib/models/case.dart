import 'package:cloud_firestore/cloud_firestore.dart';

class Case {
  final String id;
  final String patientId;
  final String patientName; // Denormalized for easier display
  final String toothNumber;
  final DateTime caseDate;
  final DateTime updatedAt;
  final String caseTitle;
  final String caseStatus; // Uploaded | Under Review | Completed
  final List<String> imageUrls; // Firebase Storage URLs
  final List<String> scanIds; // Linked scan document IDs
  final Map<String, dynamic> analysisResults; // AI analysis output
  final String notes;
  final String reviewNotes;

  Case({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.toothNumber,
    required this.caseDate,
    DateTime? updatedAt,
    this.caseTitle = '',
    this.caseStatus = 'Uploaded',
    required this.imageUrls,
    List<String>? scanIds,
    required this.analysisResults,
    required this.notes,
    this.reviewNotes = '',
  }) : scanIds = scanIds ?? const [],
       updatedAt = updatedAt ?? caseDate;

  // Convert Case to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'toothNumber': toothNumber,
      'caseDate': Timestamp.fromDate(caseDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'caseTitle': caseTitle,
      'caseStatus': caseStatus,
      'imageUrls': imageUrls,
      'scanIds': scanIds,
      'analysisResults': analysisResults,
      'notes': notes,
      'reviewNotes': reviewNotes,
    };
  }

  // Create Case from Firestore DocumentSnapshot
  factory Case.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Case(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      toothNumber: data['toothNumber'] ?? '',
      caseDate: (data['caseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      caseTitle: data['caseTitle'] ?? '',
      caseStatus: data['caseStatus'] ?? 'Uploaded',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      scanIds: List<String>.from(data['scanIds'] ?? []),
      analysisResults: Map<String, dynamic>.from(data['analysisResults'] ?? {}),
      notes: data['notes'] ?? '',
      reviewNotes: data['reviewNotes'] ?? '',
    );
  }

  // Check if analysis is complete
  bool get isAnalysisComplete {
    final status = analysisResults['status'] as String?;
    return status != null &&
        status.toLowerCase() != 'pending' &&
        status != 'Pending AI Analysis';
  }

  // Get analysis status string
  String get analysisStatus {
    return analysisResults['status'] as String? ?? 'Pending AI Analysis';
  }

  String get lifecycleStatus => caseStatus;

  // Check if case has cavity detected (from analysis)
  bool get hasCavity {
    final result = analysisResults['hasCavity'] as bool?;
    return result ?? false;
  }

  // Get cavity status string for display
  String get cavityStatus {
    if (!isAnalysisComplete) return 'Pending';
    return hasCavity ? 'Cavity' : 'Healthy';
  }

  // Get confidence from analysis
  double get confidence {
    final conf = analysisResults['confidence'];
    if (conf is num) return conf.toDouble();
    return 0.0;
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(caseDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  // Copy with method for updates
  Case copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? toothNumber,
    DateTime? caseDate,
    DateTime? updatedAt,
    String? caseTitle,
    String? caseStatus,
    List<String>? imageUrls,
    List<String>? scanIds,
    Map<String, dynamic>? analysisResults,
    String? notes,
    String? reviewNotes,
  }) {
    return Case(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      toothNumber: toothNumber ?? this.toothNumber,
      caseDate: caseDate ?? this.caseDate,
      updatedAt: updatedAt ?? this.updatedAt,
      caseTitle: caseTitle ?? this.caseTitle,
      caseStatus: caseStatus ?? this.caseStatus,
      imageUrls: imageUrls ?? this.imageUrls,
      scanIds: scanIds ?? this.scanIds,
      analysisResults: analysisResults ?? this.analysisResults,
      notes: notes ?? this.notes,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }
}
