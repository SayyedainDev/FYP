import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/models/assignment.dart';
import 'package:dental_care/models/assignment_submission.dart';
import 'package:dental_care/features/assignments/services/assignment_service.dart';

class AssignmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  AssignmentProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
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
      final querySnapshot = await _firestore.collection('assignments').get();

      _assignments = querySnapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .where((assignment) =>
              assignment.assignedTo.isEmpty ||
              assignment.assignedTo.contains(studentId))
          .toList();

      // Client-side sort by dueDate
      _assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
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
          .get();

      _assignments = querySnapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();

      // Client-side sort by createdAt
      _assignments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _errorMessage = 'Failed to load assignments: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new assignment with optional file
  Future<bool> createAssignment({
    required String title,
    required String description,
    required String subject,
    required double totalMarks,
    required DateTime dueDate,
    required String instructorId,
    required List<String> assignedTo,
    Uint8List? fileBytes,
    String? fileName,
    String? mimeType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectiveAssignedTo =
          assignedTo.isNotEmpty ? assignedTo : await _fetchStudentIds();

      final assignment = await AssignmentService.instance.createAssignment(
        title: title,
        description: description,
        subject: subject,
        totalMarks: totalMarks,
        dueDate: dueDate,
        instructorId: instructorId,
        assignedTo: effectiveAssignedTo,
        fileBytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      _assignments.insert(0, assignment);
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
          .collection('assignment_submissions')
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
          .collection('assignment_submissions')
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

  Future<void> fetchInstructorSubmissions(String instructorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final assignmentIds = await _fetchInstructorAssignmentIds(instructorId);

      if (assignmentIds.isEmpty) {
        _submissions = [];
        return;
      }

      final allSubmissions = <AssignmentSubmission>[];
      for (final chunk in _chunkList(assignmentIds, 30)) {
        final querySnapshot = await _firestore
            .collection('assignment_submissions')
            .where('assignmentId', whereIn: chunk)
            .get();

        allSubmissions.addAll(querySnapshot.docs
            .map((doc) => AssignmentSubmission.fromFirestore(doc)));
      }

      allSubmissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      _submissions = allSubmissions;
    } catch (e) {
      _errorMessage = 'Failed to load instructor submissions: $e';
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
          .collection('assignment_submissions')
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

  Future<void> fetchStudentSubmissions(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignment_submissions')
          .where('studentId', isEqualTo: studentId)
          .get();

      _submissions = querySnapshot.docs
          .map((doc) => AssignmentSubmission.fromFirestore(doc))
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load student submissions: $e';
      debugPrint(_errorMessage);
    }
  }

  Future<List<String>> _fetchStudentIds() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Failed to fetch student ids: $e');
      return [];
    }
  }

  Future<List<String>> _fetchInstructorAssignmentIds(
      String instructorId) async {
    try {
      if (_assignments.isNotEmpty) {
        return _assignments
            .where((assignment) => assignment.instructorId == instructorId)
            .map((assignment) => assignment.id)
            .toList();
      }

      final querySnapshot = await _firestore
          .collection('assignments')
          .where('instructorId', isEqualTo: instructorId)
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Failed to fetch instructor assignment ids: $e');
      return [];
    }
  }

  List<List<T>> _chunkList<T>(List<T> items, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      chunks.add(items.sublist(
          i, i + chunkSize > items.length ? items.length : i + chunkSize));
    }
    return chunks;
  }
}

extension on AssignmentSubmission {
  // ignore: unused_element
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
