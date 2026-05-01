import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/core/config/supabase_config.dart';
import '../models/lecture_note_model.dart';

class LectureNoteService {
  LectureNoteService._internal();
  static final LectureNoteService instance = LectureNoteService._internal();

  final _firestore = FirebaseFirestore.instance;
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
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName =
          fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
      final storagePath = 'notes/$uploadedByUid/${timestamp}_$cleanFileName';

      // Step A - Upload to Supabase Storage with timeout
      String publicUrl;
      try {
        final path = storagePath;
        await SupabaseConfig.client.storage
            .from('lecture-notes')
            .uploadBinary(
              path,
              fileBytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            )
            .timeout(const Duration(seconds: 120));

        publicUrl = SupabaseConfig.client.storage
            .from('lecture-notes')
            .getPublicUrl(path);
      } catch (e) {
        throw Exception('Supabase Storage upload failed: $e');
      }

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
      try {
        await docRef.set(note.toFirestore());
      } catch (e) {
        throw Exception(
            'Firestore save failed: Check that lecture_notes collection rules allow write access. Error: $e');
      }

      // Step E - Return
      return note;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<LectureNoteModel>> streamNotesByModule(String moduleId) {
    return _firestore
        .collection(_collection)
        .where('moduleId', isEqualTo: moduleId)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs
          .map((doc) => LectureNoteModel.fromFirestore(doc))
          .toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    });
  }

  Stream<List<LectureNoteModel>> streamNotesByUser(String uid) {
    return _firestore
        .collection(_collection)
        .where('uploadedByUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs
          .map((doc) => LectureNoteModel.fromFirestore(doc))
          .toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
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
    // Step A - Delete file from Supabase Storage
    try {
      if (note.storagePath.isNotEmpty) {
        await SupabaseConfig.client.storage
            .from('lecture-notes')
            .remove([note.storagePath]);
      }
    } catch (e) {
      debugPrint('Failed to delete file from Supabase storage: $e');
    }

    // Step B - Delete Firestore document only if Step A succeeds
    await _firestore.collection(_collection).doc(note.id).delete();
  }
}
