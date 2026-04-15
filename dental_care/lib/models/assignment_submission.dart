import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String submissionFileUrl;
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
    required this.submissionFileUrl,
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
      'submissionFileUrl': submissionFileUrl,
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
      submissionFileUrl: data['submissionFileUrl'] ?? '',
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
}
