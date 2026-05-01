import 'package:flutter/foundation.dart';
import '../models/lecture_note_model.dart';
import '../services/lecture_note_service.dart';

enum LectureNoteStatus { idle, loading, uploading, success, error }

class LectureNoteProvider extends ChangeNotifier {
  LectureNoteStatus _status = LectureNoteStatus.idle;
  List<LectureNoteModel> _notes = [];
  String? _errorMessage;
  double _uploadProgress = 0.0;

  LectureNoteStatus get status => _status;
  List<LectureNoteModel> get notes => _notes;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;

  bool get isLoading => _status == LectureNoteStatus.loading;
  bool get isUploading => _status == LectureNoteStatus.uploading;

  Stream<List<LectureNoteModel>> streamByModule(String moduleId) {
    return LectureNoteService.instance.streamNotesByModule(moduleId);
  }

  Stream<List<LectureNoteModel>> streamByUser(String uid) {
    return LectureNoteService.instance.streamNotesByUser(uid);
  }

  Future<void> fetchAll() async {
    _status = LectureNoteStatus.loading;
    notifyListeners();

    try {
      _notes = await LectureNoteService.instance.fetchAllNotes();
      _status = LectureNoteStatus.success;
    } catch (e, stack) {
      _status = LectureNoteStatus.error;
      _errorMessage = 'Failed to load notes: \${e.toString()}';
      debugPrint('Error in fetchAll: $e\\n$stack');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> uploadNote({
    required String title,
    String? description,
    required String moduleId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required String uploadedByUid,
    required String uploadedByName,
  }) async {
    _status = LectureNoteStatus.uploading;
    _uploadProgress = 0.0;
    notifyListeners();

    // Fake progress tick for web
    _uploadProgress = 0.3;
    notifyListeners();

    try {
      final note = await LectureNoteService.instance.uploadNote(
        title: title,
        description: description,
        moduleId: moduleId,
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
        uploadedByUid: uploadedByUid,
        uploadedByName: uploadedByName,
      );

      _uploadProgress = 1.0;
      _notes.insert(0, note);
      _status = LectureNoteStatus.success;
      notifyListeners();
      return true;
    } catch (e, stack) {
      _status = LectureNoteStatus.error;
      _errorMessage = 'Failed to upload note: ${e.toString()}';
      debugPrint('Error in uploadNote: $e\n$stack');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(LectureNoteModel note) async {
    try {
      await LectureNoteService.instance.deleteNote(note);
      _notes.removeWhere((n) => n.id == note.id);
      notifyListeners();
      return true;
    } catch (e, stack) {
      _errorMessage =
          'Failed to delete note. Ensure both database and storage are reachable. \${e.toString()}';
      debugPrint('Error in deleteNote: $e\\n$stack');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
