import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/models/student_performance.dart';

class PerformanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StudentPerformance? _performance;
  List<StudentPerformance> _allStudentsPerformance = [];
  bool _isLoading = false;
  String? _errorMessage;

  StudentPerformance? get performance => _performance;
  List<StudentPerformance> get allStudentsPerformance =>
      _allStudentsPerformance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch student's own performance
  Future<void> fetchStudentPerformance(
      String studentId, String instructorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('studentPerformance')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _performance =
            StudentPerformance.fromFirestore(querySnapshot.docs.first);
      }
    } catch (e) {
      _errorMessage = 'Failed to load performance: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all students' performance for instructor
  Future<void> fetchInstructorStudentsPerformance(String instructorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('studentPerformance')
          .where('instructorId', isEqualTo: instructorId)
          .orderBy('overallPerformanceScore', descending: true)
          .get();

      _allStudentsPerformance = querySnapshot.docs
          .map((doc) => StudentPerformance.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load students performance: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update performance after quiz completion
  Future<void> updatePerformanceAfterQuiz(
    String studentId,
    String instructorId,
    double newScore,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('studentPerformance')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final currentPerformance = StudentPerformance.fromFirestore(doc);

        final newTotalQuizzes = currentPerformance.totalQuizzesTaken + 1;
        final newAverageScore = ((currentPerformance.averageQuizScore *
                    currentPerformance.totalQuizzesTaken) +
                newScore) /
            newTotalQuizzes;
        final newOverallScore =
            (newAverageScore + currentPerformance.averageAssignmentScore) / 2;

        await doc.reference.update({
          'totalQuizzesTaken': newTotalQuizzes,
          'averageQuizScore': newAverageScore,
          'overallPerformanceScore': newOverallScore,
          'lastActivityDate': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('Error updating performance: $e');
    }
  }

  // Update performance after assignment grading
  Future<void> updatePerformanceAfterAssignment(
    String studentId,
    String instructorId,
    double marksObtained,
    double totalMarks,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('studentPerformance')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final currentPerformance = StudentPerformance.fromFirestore(doc);
        final scorePercentage = (marksObtained / totalMarks) * 100;

        final newAssignmentsSubmitted =
            currentPerformance.assignmentsSubmitted + 1;
        final newAverageAssignmentScore =
            ((currentPerformance.averageAssignmentScore *
                        currentPerformance.assignmentsSubmitted) +
                    scorePercentage) /
                newAssignmentsSubmitted;
        final newOverallScore =
            (currentPerformance.averageQuizScore + newAverageAssignmentScore) /
                2;

        await doc.reference.update({
          'assignmentsSubmitted': newAssignmentsSubmitted,
          'averageAssignmentScore': newAverageAssignmentScore,
          'overallPerformanceScore': newOverallScore,
          'lastActivityDate': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('Error updating performance: $e');
    }
  }

  // Get performance rank among students
  int getStudentRank(String studentId) {
    final rank =
        _allStudentsPerformance.indexWhere((p) => p.studentId == studentId);
    return rank + 1;
  }

  // Get average performance score
  double getAveragePerformanceScore() {
    if (_allStudentsPerformance.isEmpty) return 0;
    final sum = _allStudentsPerformance.fold<double>(
        0, (previous, current) => previous + current.overallPerformanceScore);
    return sum / _allStudentsPerformance.length;
  }
}
