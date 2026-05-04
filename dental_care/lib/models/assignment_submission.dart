import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String submissionFileUrl;
  final String fileName;
  final String submissionNotes;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final double? marksObtained;
  final String? feedback;
  final String status; // Submitted, Graded, Late
  final bool isLate;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.submissionFileUrl,
    required this.fileName,
    required this.submissionNotes,
    required this.submittedAt,
    this.gradedAt,
    this.marksObtained,
    this.feedback,
    required this.status,
    required this.isLate,
  });

  double get percentage =>
      marksObtained != null ? (marksObtained! / 100) * 100 : 0;

  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'submissionFileUrl': submissionFileUrl,
      'fileName': fileName,
      'submissionNotes': submissionNotes,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'marksObtained': marksObtained,
      'feedback': feedback,
      'status': status,
      'isLate': isLate,
    };
  }

  factory AssignmentSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentSubmission(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? data['studentId'] ?? '',
      submissionFileUrl: data['submissionFileUrl'] ?? '',
      fileName: data['fileName'] ?? 'Submission File',
      submissionNotes: data['submissionNotes'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      gradedAt: data['gradedAt'] != null
          ? (data['gradedAt'] as Timestamp).toDate()
          : null,
      marksObtained: (data['marksObtained'] ?? 0).toDouble(),
      feedback: data['feedback'],
      status: data['status'] ?? 'Submitted',
      isLate: data['isLate'] ?? false,
    );
  }

  AssignmentSubmission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? submissionFileUrl,
    String? fileName,
    String? submissionNotes,
    DateTime? submittedAt,
    DateTime? gradedAt,
    double? marksObtained,
    String? feedback,
    String? status,
    bool? isLate,
  }) {
    return AssignmentSubmission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submissionFileUrl: submissionFileUrl ?? this.submissionFileUrl,
      fileName: fileName ?? this.fileName,
      submissionNotes: submissionNotes ?? this.submissionNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      marksObtained: marksObtained ?? this.marksObtained,
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
      isLate: isLate ?? this.isLate,
    );
  }
}
