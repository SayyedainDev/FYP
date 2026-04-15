import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/models/assignment.dart';
import 'package:dental_care/models/assignment_submission.dart';

class AssignmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Assignment> _assignments = [];
  List<AssignmentSubmission> _submissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Assignment> get assignments => _assignments;
  List<AssignmentSubmission> get submissions => _submissions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch assignments for a student
  Future<void> fetchStudentAssignments(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('assignedTo', arrayContains: studentId)
          .orderBy('dueDate', descending: false)
          .get();

      _assignments = querySnapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load assignments: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch instructor's assignments
  Future<void> fetchInstructorAssignments(String instructorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('instructorId', isEqualTo: instructorId)
          .orderBy('createdAt', descending: true)
          .get();

      _assignments = querySnapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load assignments: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new assignment
  Future<bool> createAssignment(Assignment assignment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('assignments')
          .doc(assignment.id)
          .set(assignment.toFirestore());

      _assignments.add(assignment);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create assignment: $e';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Submit assignment
  Future<bool> submitAssignment(AssignmentSubmission submission) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('assignmentSubmissions')
          .doc(submission.id)
          .set(submission.toFirestore());

      _submissions.add(submission);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit assignment: $e';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch submissions for an assignment
  Future<void> fetchAssignmentSubmissions(String assignmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      _submissions = querySnapshot.docs
          .map((doc) => AssignmentSubmission.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load submissions: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Grade assignment
  Future<bool> gradeAssignment(
      String submissionId, double marks, String feedback) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('assignmentSubmissions')
          .doc(submissionId)
          .update({
        'marksObtained': marks,
        'feedback': feedback,
        'status': 'Graded',
        'gradedAt': Timestamp.now(),
      });

      final index = _submissions.indexWhere((sub) => sub.id == submissionId);
      if (index != -1) {
        _submissions[index] = _submissions[index].copyWith(
          marksObtained: marks,
          feedback: feedback,
          status: 'Graded',
          gradedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to grade assignment: $e';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get assignment by ID
  Assignment? getAssignmentById(String id) {
    try {
      return _assignments.firstWhere((assignment) => assignment.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get student's submissions for an assignment
  List<AssignmentSubmission> getStudentSubmissions(
      String studentId, String assignmentId) {
    return _submissions
        .where((sub) =>
            sub.studentId == studentId && sub.assignmentId == assignmentId)
        .toList();
  }
}

extension on AssignmentSubmission {
  AssignmentSubmission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? submissionFileUrl,
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
      submissionFileUrl: submissionFileUrl ?? this.submissionFileUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      marksObtained: marksObtained ?? this.marksObtained,
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
      isLate: isLate ?? this.isLate,
    );
  }
}
