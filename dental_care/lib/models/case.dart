import 'package:cloud_firestore/cloud_firestore.dart';

class Case {
  final String id;
  final String patientId;
  final String patientName; // Denormalized for easier display
  final String toothNumber;
  final DateTime caseDate;
  final List<String> imageUrls; // Firebase Storage URLs
  final Map<String, dynamic> analysisResults; // AI analysis output
  final String notes;

  Case({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.toothNumber,
    required this.caseDate,
    required this.imageUrls,
    required this.analysisResults,
    required this.notes,
  });

  // Convert Case to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'toothNumber': toothNumber,
      'caseDate': Timestamp.fromDate(caseDate),
      'imageUrls': imageUrls,
      'analysisResults': analysisResults,
      'notes': notes,
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
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      analysisResults: Map<String, dynamic>.from(data['analysisResults'] ?? {}),
      notes: data['notes'] ?? '',
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
    List<String>? imageUrls,
    Map<String, dynamic>? analysisResults,
    String? notes,
  }) {
    return Case(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      toothNumber: toothNumber ?? this.toothNumber,
      caseDate: caseDate ?? this.caseDate,
      imageUrls: imageUrls ?? this.imageUrls,
      analysisResults: analysisResults ?? this.analysisResults,
      notes: notes ?? this.notes,
    );
  }
}
