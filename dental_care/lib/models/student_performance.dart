import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPerformance {
  final String id;
  final String studentId;
  final String instructorId;
  final int totalQuizzesTaken;
  final double averageQuizScore;
  final int assignmentsSubmitted;
  final double averageAssignmentScore;
  final int lectureVideosWatched;
  final double overallPerformanceScore;
  final DateTime lastActivityDate;
  final DateTime createdAt;
  final Map<String, dynamic> performanceMetrics;

  StudentPerformance({
    required this.id,
    required this.studentId,
    required this.instructorId,
    required this.totalQuizzesTaken,
    required this.averageQuizScore,
    required this.assignmentsSubmitted,
    required this.averageAssignmentScore,
    required this.lectureVideosWatched,
    required this.overallPerformanceScore,
    required this.lastActivityDate,
    required this.createdAt,
    required this.performanceMetrics,
  });

  String get performanceStatus {
    if (overallPerformanceScore >= 80) return 'Excellent';
    if (overallPerformanceScore >= 70) return 'Good';
    if (overallPerformanceScore >= 60) return 'Average';
    return 'Needs Improvement';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'instructorId': instructorId,
      'totalQuizzesTaken': totalQuizzesTaken,
      'averageQuizScore': averageQuizScore,
      'assignmentsSubmitted': assignmentsSubmitted,
      'averageAssignmentScore': averageAssignmentScore,
      'lectureVideosWatched': lectureVideosWatched,
      'overallPerformanceScore': overallPerformanceScore,
      'lastActivityDate': Timestamp.fromDate(lastActivityDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'performanceMetrics': performanceMetrics,
    };
  }

  factory StudentPerformance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentPerformance(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      instructorId: data['instructorId'] ?? '',
      totalQuizzesTaken: data['totalQuizzesTaken'] ?? 0,
      averageQuizScore: (data['averageQuizScore'] ?? 0).toDouble(),
      assignmentsSubmitted: data['assignmentsSubmitted'] ?? 0,
      averageAssignmentScore: (data['averageAssignmentScore'] ?? 0).toDouble(),
      lectureVideosWatched: data['lectureVideosWatched'] ?? 0,
      overallPerformanceScore:
          (data['overallPerformanceScore'] ?? 0).toDouble(),
      lastActivityDate: (data['lastActivityDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      performanceMetrics: data['performanceMetrics'] ?? {},
    );
  }
}
