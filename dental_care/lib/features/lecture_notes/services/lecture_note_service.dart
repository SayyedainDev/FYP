import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lecture_note_model.dart';

class LectureNoteService {
  LectureNoteService._internal();
  static final LectureNoteService instance = LectureNoteService._internal();

  final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  final _bucket = 'lecture-notes';
  final _collection = 'lecture_notes';

  Future<LectureNoteModel> uploadNote({
    required String title,
    String? description,
    required String moduleId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required String uploadedByUid,
    required String uploadedByName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    final storagePath = 'notes/$uploadedByUid/${timestamp}_$cleanFileName';

    // Step A - Upload to Supabase Storage
    await _supabase.storage.from(_bucket).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(storagePath);

    // Step B - Generate Firestore document ID
    final docRef = _firestore.collection(_collection).doc();
    final docId = docRef.id;

    // Step C - Build Model
    final note = LectureNoteModel(
      id: docId,
      title: title,
      description: description,
      moduleId: moduleId,
      fileUrl: publicUrl,
      storagePath: storagePath,
      fileName: fileName,
      uploadedByUid: uploadedByUid,
      uploadedByName: uploadedByName,
      createdAt: DateTime.now(),
    );

    // Step D - Write to Firestore
    await docRef.set(note.toFirestore());

    // Step E - Return
    return note;
  }

  Stream<List<LectureNoteModel>> streamNotesByModule(String moduleId) {
    return _firestore
        .collection(_collection)
        .where('moduleId', isEqualTo: moduleId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Phase 2: Add pagination limit
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LectureNoteModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<LectureNoteModel>> fetchAllNotes() async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(50) // Phase 2: Add pagination limit
        .get();

    return querySnapshot.docs
        .map((doc) => LectureNoteModel.fromFirestore(doc))
        .toList();
  }

  Future<void> deleteNote(LectureNoteModel note) async {
    // Step A - Delete file from Supabase Storage using exact path
    try {
      if (note.storagePath.isNotEmpty) {
        await _supabase.storage.from(_bucket).remove([note.storagePath]);
      } else {
        // Fallback for old documents that didn't have storagePath saved
        final uri = Uri.parse(note.fileUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf(_bucket);
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final fallbackPath = pathSegments.sublist(bucketIndex + 1).join('/');
          await _supabase.storage.from(_bucket).remove([fallbackPath]);
        }
      }
    } catch (e, stack) {
      // Do NOT swallow the error. If Supabase fails, the file is orphaned.
      throw Exception('Failed to delete file from storage: $e');
    }

    // Step B - Delete Firestore document only if Step A succeeds
    await _firestore.collection(_collection).doc(note.id).delete();
  }
}
