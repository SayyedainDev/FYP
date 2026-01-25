import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lecture_note.dart';

class LectureNotesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'lecture_notes';

  List<LectureNote> _lectureNotes = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;
  LectureNote? _currentNote;

  // Getters
  List<LectureNote> get lectureNotes => _lectureNotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;
  LectureNote? get currentNote => _currentNote;

  // Stream of lecture notes for a specific dentist
  Stream<List<LectureNote>> getLectureNotesStream(String dentistUid) {
    return _firestore
        .collection('lecture_notes')
        .where('dentistUid', isEqualTo: dentistUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LectureNote.fromFirestore(doc))
              .toList(),
        );
  }

  // Fetch all lecture notes for a dentist
  Future<void> fetchLectureNotes(String dentistUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('lecture_notes')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('createdAt', descending: true)
          .get();

      _lectureNotes = snapshot.docs
          .map((doc) => LectureNote.fromFirestore(doc))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch lecture notes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload file to Supabase Storage
  Future<String?> uploadLectureNoteFile({
    required File file,
    required String dentistUid,
    required String noteId,
    required String fileName,
  }) async {
    try {
      _uploadProgress = 0.0;
      notifyListeners();

      // Path: lecture_notes/{dentistUid}/{noteId}/{fileName}
      final filePath = '$dentistUid/$noteId/$fileName';

      // Read file bytes
      final bytes = await file.readAsBytes();

      // Upload to Supabase Storage
      await _supabase.storage.from(_bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(filePath);

      _uploadProgress = 1.0;
      notifyListeners();

      return publicUrl;
    } catch (e) {
      _errorMessage = 'Failed to upload file: $e';
      _uploadProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  // Upload file from bytes (for web)
  Future<String?> uploadLectureNoteFileFromBytes({
    required Uint8List bytes,
    required String dentistUid,
    required String noteId,
    required String fileName,
  }) async {
    try {
      _uploadProgress = 0.0;
      notifyListeners();

      // Path: lecture_notes/{dentistUid}/{noteId}/{fileName}
      final filePath = '$dentistUid/$noteId/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage.from(_bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(filePath);

      _uploadProgress = 1.0;
      notifyListeners();

      return publicUrl;
    } catch (e) {
      _errorMessage = 'Failed to upload file: $e';
      _uploadProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  // Create lecture note with file upload from bytes (for web)
  Future<bool> createLectureNoteWithFileBytes({
    required String dentistUid,
    required String title,
    required String description,
    required Uint8List bytes,
    required String fileName,
    required List<String> tags,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final noteId = _firestore.collection('lecture_notes').doc().id;
      final fileSize = bytes.length;

      // Determine file type
      final ext = fileName.toLowerCase().split('.').last;
      final type = _getFileType(ext);

      // Upload file to Supabase
      final fileUrl = await uploadLectureNoteFileFromBytes(
        bytes: bytes,
        dentistUid: dentistUid,
        noteId: noteId,
        fileName: fileName,
      );

      if (fileUrl == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create lecture note document in Firestore
      final lectureNote = LectureNote(
        id: noteId,
        dentistUid: dentistUid,
        title: title,
        description: description,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSizeBytes: fileSize,
        tags: tags,
        createdAt: DateTime.now(),
        isPublished: true,
      );

      await _firestore
          .collection('lecture_notes')
          .doc(noteId)
          .set(lectureNote.toFirestore());

      _lectureNotes.insert(0, lectureNote);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create lecture note: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create lecture note with file upload
  Future<bool> createLectureNoteWithFile({
    required String dentistUid,
    required String title,
    required String description,
    required File file,
    required String fileName,
    required List<String> tags,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final noteId = _firestore.collection('lecture_notes').doc().id;
      final fileSize = file.lengthSync();

      // Determine file type
      final ext = fileName.toLowerCase().split('.').last;
      final type = _getFileType(ext);

      // Upload file to Supabase
      final fileUrl = await uploadLectureNoteFile(
        file: file,
        dentistUid: dentistUid,
        noteId: noteId,
        fileName: fileName,
      );

      if (fileUrl == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create lecture note document in Firestore
      final lectureNote = LectureNote(
        id: noteId,
        dentistUid: dentistUid,
        title: title,
        description: description,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSizeBytes: fileSize,
        tags: tags,
        createdAt: DateTime.now(),
        isPublished: true,
      );

      await _firestore
          .collection('lecture_notes')
          .doc(noteId)
          .set(lectureNote.toFirestore());

      _lectureNotes.insert(0, lectureNote);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create lecture note: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create custom notes (text-based)
  Future<bool> createCustomNotes({
    required String dentistUid,
    required String title,
    required String description,
    required String customNotes,
    required List<String> tags,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final noteId = _firestore.collection('lecture_notes').doc().id;

      final lectureNote = LectureNote(
        id: noteId,
        dentistUid: dentistUid,
        title: title,
        description: description,
        type: NoteType.custom,
        customNotes: customNotes,
        tags: tags,
        createdAt: DateTime.now(),
        isPublished: true,
      );

      await _firestore
          .collection('lecture_notes')
          .doc(noteId)
          .set(lectureNote.toFirestore());

      _lectureNotes.insert(0, lectureNote);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create custom notes: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete lecture note
  Future<bool> deleteLectureNote(LectureNote note) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete file from Supabase Storage if it exists
      if (note.fileUrl != null && note.fileName != null) {
        try {
          final filePath = '${note.dentistUid}/${note.id}/${note.fileName}';
          await _supabase.storage.from(_bucketName).remove([filePath]);
        } catch (e) {
          // File might already be deleted, continue anyway
        }
      }

      // Delete document from Firestore
      await _firestore.collection('lecture_notes').doc(note.id).delete();

      _lectureNotes.removeWhere((n) => n.id == note.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete lecture note: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update lecture note
  Future<bool> updateLectureNote(LectureNote note) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('lecture_notes')
          .doc(note.id)
          .update(note.toFirestore());

      final index = _lectureNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _lectureNotes[index] = note;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update lecture note: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get file type from extension
  NoteType _getFileType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return NoteType.pdf;
      case 'doc':
        return NoteType.doc;
      case 'docx':
        return NoteType.docx;
      case 'ppt':
      case 'pptx':
        return NoteType.pptx;
      case 'txt':
        return NoteType.txt;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return NoteType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return NoteType.video;
      default:
        return NoteType.custom;
    }
  }
}
