import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/core/config/supabase_config.dart';
import 'package:dental_care/models/assignment.dart';
import '../models/assignment_submission_model.dart';

/// Service for handling assignment submissions with Supabase Storage integration
class AssignmentService {
  AssignmentService._internal();
  static final AssignmentService instance = AssignmentService._internal();


  final _firestore = FirebaseFirestore.instance;
  final _submissionsCollection = 'assignment_submissions';
  final _assignmentsCollection = 'assignments';

  /// Create a new assignment with an optional prompt file
  Future<Assignment> createAssignment({
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
    String publicUrl = '';
    String storagePath = '';

    if (fileBytes != null && fileName != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName =
          fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
      storagePath = 'assignments/$instructorId/${timestamp}_$cleanFileName';

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from('assignment-submissions') // Using the same bucket for consistency
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
                contentType: mimeType ?? 'application/octet-stream',
                upsert: true),
          )
          .timeout(const Duration(seconds: 120));

      publicUrl = SupabaseConfig.client.storage
          .from('assignment-submissions')
          .getPublicUrl(storagePath);
    }

    final docRef = _firestore.collection(_assignmentsCollection).doc();
    final assignment = Assignment(
      id: docRef.id,
      instructorId: instructorId,
      title: title,
      description: description,
      subject: subject,
      dueDate: dueDate,
      totalMarks: totalMarks,
      assignedTo: assignedTo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fileUrl: publicUrl,
      storagePath: storagePath,
      status: 'Active',
    );

    await docRef.set(assignment.toFirestore());
    return assignment;
  }

  /// Upload assignment submission file to Supabase Storage and save metadata to Firestore
  Future<AssignmentSubmissionModel> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required String submissionNotes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    final storagePath =
        'submissions/$assignmentId/$studentId/${timestamp}_$cleanFileName';

    // Step A - Upload to Supabase Storage
    await SupabaseConfig.client.storage
        .from('assignment-submissions')
        .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        )
        .timeout(const Duration(seconds: 120));
    final publicUrl = SupabaseConfig.client.storage
        .from('assignment-submissions')
        .getPublicUrl(storagePath);

    // Step B - Generate Firestore document ID
    final docRef = _firestore.collection(_submissionsCollection).doc();
    final docId = docRef.id;

    // Step C - Build Model
    final submission = AssignmentSubmissionModel(
      id: docId,
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: studentName,
      submissionFileUrl: publicUrl,
      storagePathFile: storagePath,
      fileName: fileName,
      submissionNotes: submissionNotes,
      submittedAt: DateTime.now(),
      status: 'Submitted',
      isLate: false, // Timestamp will be validated by business logic
    );

    // Step D - Write to Firestore
    await docRef.set(submission.toFirestore());

    // Step E - Return the submission model
    return submission;
  }

  /// Fetch all submissions for a specific assignment
  Stream<List<AssignmentSubmissionModel>> streamAssignmentSubmissions(
    String assignmentId,
  ) {
    return _firestore
        .collection(_submissionsCollection)
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snapshot) {
      final subs = snapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromFirestore(doc))
          .toList();
      subs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return subs;
    });
  }

  /// Fetch all submissions by a specific student
  Stream<List<AssignmentSubmissionModel>> streamStudentSubmissions(
    String studentId,
  ) {
    return _firestore
        .collection(_submissionsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final subs = snapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromFirestore(doc))
          .toList();
      subs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return subs;
    });
  }

  /// Fetch submission by document ID
  Future<AssignmentSubmissionModel?> getSubmission(String submissionId) async {
    try {
      final doc =
          await _firestore.collection(_submissionsCollection).doc(submissionId).get();

      if (doc.exists) {
        return AssignmentSubmissionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch submission: $e');
    }
  }

  /// Update submission status (e.g., mark as graded)
  Future<void> updateSubmissionStatus({
    required String submissionId,
    required String status,
    double? marksObtained,
    String? feedback,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (marksObtained != null) {
        updateData['marksObtained'] = marksObtained;
      }

      if (feedback != null) {
        updateData['feedback'] = feedback;
      }

      await _firestore
          .collection(_submissionsCollection)
          .doc(submissionId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update submission: $e');
    }
  }

  /// Delete submission (both file and metadata)
  Future<void> deleteSubmission(AssignmentSubmissionModel submission) async {
    // Step A - Delete file from Supabase Storage
    try {
      if (submission.storagePathFile.isNotEmpty) {
        await SupabaseConfig.client.storage
            .from('assignment-submissions')
            .remove([submission.storagePathFile]);
      }
    } catch (e) {
      // Log error but continue to delete Firestore document if file is missing
      print('Failed to delete file from Supabase storage: $e');
    }

    // Step B - Delete Firestore document only if Step A succeeds
    await _firestore.collection(_submissionsCollection).doc(submission.id).delete();
  }
}
