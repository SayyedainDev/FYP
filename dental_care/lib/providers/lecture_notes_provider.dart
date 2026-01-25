import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/lecture_note.dart';

class LectureNotesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  // Upload file for lecture notes
  Future<String?> uploadLectureNoteFile({
    required File file,
    required String dentistUid,
    required String noteId,
    required String fileName,
  }) async {
    try {
      _uploadProgress = 0.0;
      notifyListeners();

      final ref = _storage.ref().child(
        'lecture_notes/$dentistUid/$noteId/$fileName',
      );

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      _uploadProgress = 0.0;
      notifyListeners();

      return downloadUrl;
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

      final ref = _storage.ref().child(
        'lecture_notes/$dentistUid/$noteId/$fileName',
      );

      final uploadTask = ref.putData(bytes);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      _uploadProgress = 0.0;
      notifyListeners();

      return downloadUrl;
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

      // Upload file
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

      // Create lecture note document
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

      // Upload file
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

      // Create lecture note document
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

  // Update lecture note
  Future<bool> updateLectureNote({
    required String noteId,
    required String dentistUid,
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (tags != null) updates['tags'] = tags;
      updates['lastModified'] = Timestamp.now();

      await _firestore.collection('lecture_notes').doc(noteId).update(updates);

      // Update local list
      final index = _lectureNotes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _lectureNotes[index] = _lectureNotes[index].copyWith(
          title: title,
          description: description,
          tags: tags,
          lastModified: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update lecture note: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete lecture note
  Future<bool> deleteLectureNote({
    required String noteId,
    required String dentistUid,
    String? fileName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete file from storage if it exists
      if (fileName != null) {
        try {
          await _storage
              .ref()
              .child('lecture_notes/$dentistUid/$noteId/$fileName')
              .delete();
        } catch (e) {
          // File might not exist, continue anyway
        }
      }

      // Delete from Firestore
      await _firestore.collection('lecture_notes').doc(noteId).delete();

      _lectureNotes.removeWhere((note) => note.id == noteId);
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

  // Increment view count
  Future<void> incrementViewCount(String noteId) async {
    try {
      await _firestore.collection('lecture_notes').doc(noteId).update({
        'views': FieldValue.increment(1),
      });

      final index = _lectureNotes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _lectureNotes[index] = _lectureNotes[index].copyWith(
          views: _lectureNotes[index].views + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update view count: $e';
    }
  }

  // Get lecture notes by tags
  List<LectureNote> getLectureNotesByTag(String tag) {
    return _lectureNotes.where((note) => note.tags.contains(tag)).toList();
  }

  // Search lecture notes
  List<LectureNote> searchLectureNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _lectureNotes
        .where(
          (note) =>
              note.title.toLowerCase().contains(lowerQuery) ||
              note.description.toLowerCase().contains(lowerQuery) ||
              note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }

  // Helper method to determine file type
  NoteType _getFileType(String extension) {
    switch (extension) {
      case 'pdf':
        return NoteType.pdf;
      case 'doc':
        return NoteType.doc;
      case 'docx':
        return NoteType.docx;
      case 'pptx':
      case 'ppt':
        return NoteType.pptx;
      case 'txt':
        return NoteType.txt;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
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

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
