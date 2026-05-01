import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for assignment submissions with file storage support
class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String submissionFileUrl; // Public URL from Firebase Storage
  final String storagePathFile; // Storage path for deletion
  final String fileName;
  final String submissionNotes;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final double? marksObtained;
  final String? feedback;
  final String status; // Submitted, Graded, Late, Pending
  final bool isLate;
  final DateTime? updatedAt;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.submissionFileUrl,
    required this.storagePathFile,
    required this.fileName,
    required this.submissionNotes,
    required this.submittedAt,
    this.gradedAt,
    this.marksObtained,
    this.feedback,
    required this.status,
    required this.isLate,
    this.updatedAt,
  });

  /// Calculate percentage of marks obtained
  double get percentage =>
      marksObtained != null ? (marksObtained! / 100) * 100 : 0;

  /// Check if submission is within due time
  bool get isOnTime => !isLate;

  /// Convert model to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'submissionFileUrl': submissionFileUrl,
      'storagePathFile': storagePathFile,
      'fileName': fileName,
      'submissionNotes': submissionNotes,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'marksObtained': marksObtained,
      'feedback': feedback,
      'status': status,
      'isLate': isLate,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create model from Firestore document
  factory AssignmentSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentSubmissionModel(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      submissionFileUrl: data['submissionFileUrl'] ?? '',
      storagePathFile: data['storagePathFile'] ?? '',
      fileName: data['fileName'] ?? '',
      submissionNotes: data['submissionNotes'] ?? '',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gradedAt: data['gradedAt'] != null
          ? (data['gradedAt'] as Timestamp).toDate()
          : null,
      marksObtained: (data['marksObtained'] as num?)?.toDouble(),
      feedback: data['feedback'] as String?,
      status: data['status'] ?? 'Submitted',
      isLate: data['isLate'] ?? false,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create a copy with updated fields
  AssignmentSubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? submissionFileUrl,
    String? storagePathFile,
    String? fileName,
    String? submissionNotes,
    DateTime? submittedAt,
    DateTime? gradedAt,
    double? marksObtained,
    String? feedback,
    String? status,
    bool? isLate,
    DateTime? updatedAt,
  }) {
    return AssignmentSubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submissionFileUrl: submissionFileUrl ?? this.submissionFileUrl,
      storagePathFile: storagePathFile ?? this.storagePathFile,
      fileName: fileName ?? this.fileName,
      submissionNotes: submissionNotes ?? this.submissionNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      marksObtained: marksObtained ?? this.marksObtained,
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
      isLate: isLate ?? this.isLate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
