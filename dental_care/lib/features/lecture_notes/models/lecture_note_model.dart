import 'package:cloud_firestore/cloud_firestore.dart';

class LectureNoteModel {
  final String id;
  final String title;
  final String? description;
  final String moduleId;
  final String fileUrl;
  final String storagePath;
  final String fileName;
  final String uploadedByUid;
  final String uploadedByName;
  final DateTime createdAt;

  const LectureNoteModel({
    required this.id,
    required this.title,
    this.description,
    required this.moduleId,
    required this.fileUrl,
    required this.storagePath,
    required this.fileName,
    required this.uploadedByUid,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory LectureNoteModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LectureNoteModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String?,
      moduleId: data['moduleId'] as String,
      fileUrl: data['fileUrl'] as String,
      storagePath:
          data['storagePath'] as String? ?? '', // Fallback for old data
      fileName: data['fileName'] as String,
      uploadedByUid: data['uploadedByUid'] as String,
      uploadedByName: data['uploadedByName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'moduleId': moduleId,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'fileName': fileName,
      'uploadedByUid': uploadedByUid,
      'uploadedByName': uploadedByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
