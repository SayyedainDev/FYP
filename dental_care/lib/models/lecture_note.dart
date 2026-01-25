import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType {
  pdf,
  doc,
  docx,
  pptx,
  txt,
  image,
  video,
  custom, // For manually written notes
}

class LectureNote {
  final String id;
  final String dentistUid;
  final String title;
  final String description;
  final NoteType type;
  final String? fileUrl; // For uploaded files
  final String? fileName;
  final int? fileSizeBytes;
  final String? customNotes; // For manually written notes
  final List<String> tags; // For categorization
  final DateTime createdAt;
  final DateTime? lastModified;
  final bool isPublished; // Whether it's used in quizzes or not
  final int views; // Number of times accessed
  final String? thumbnail; // For image/video thumbnails

  LectureNote({
    required this.id,
    required this.dentistUid,
    required this.title,
    required this.description,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.customNotes,
    this.tags = const [],
    required this.createdAt,
    this.lastModified,
    this.isPublished = false,
    this.views = 0,
    this.thumbnail,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'dentistUid': dentistUid,
      'title': title,
      'description': description,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'customNotes': customNotes,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': lastModified != null
          ? Timestamp.fromDate(lastModified!)
          : null,
      'isPublished': isPublished,
      'views': views,
      'thumbnail': thumbnail,
    };
  }

  factory LectureNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LectureNote(
      id: doc.id,
      dentistUid: data['dentistUid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: NoteType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NoteType.custom,
      ),
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSizeBytes: data['fileSizeBytes'],
      customNotes: data['customNotes'],
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      isPublished: data['isPublished'] ?? false,
      views: data['views'] ?? 0,
      thumbnail: data['thumbnail'],
    );
  }

  // Copy with method for updating
  LectureNote copyWith({
    String? id,
    String? dentistUid,
    String? title,
    String? description,
    NoteType? type,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? customNotes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isPublished,
    int? views,
    String? thumbnail,
  }) {
    return LectureNote(
      id: id ?? this.id,
      dentistUid: dentistUid ?? this.dentistUid,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      customNotes: customNotes ?? this.customNotes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isPublished: isPublished ?? this.isPublished,
      views: views ?? this.views,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  // Helper methods
  String get typeLabel {
    switch (type) {
      case NoteType.pdf:
        return 'PDF';
      case NoteType.doc:
        return 'Word (DOC)';
      case NoteType.docx:
        return 'Word (DOCX)';
      case NoteType.pptx:
        return 'PowerPoint';
      case NoteType.txt:
        return 'Text';
      case NoteType.image:
        return 'Image';
      case NoteType.video:
        return 'Video';
      case NoteType.custom:
        return 'Custom Notes';
    }
  }

  String get typeIcon {
    switch (type) {
      case NoteType.pdf:
        return '📄';
      case NoteType.doc:
      case NoteType.docx:
        return '📝';
      case NoteType.pptx:
        return '📊';
      case NoteType.txt:
        return '📋';
      case NoteType.image:
        return '🖼️';
      case NoteType.video:
        return '🎥';
      case NoteType.custom:
        return '✍️';
    }
  }

  String formatFileSize() {
    if (fileSizeBytes == null) return 'Unknown';
    if (fileSizeBytes! < 1024) return '${fileSizeBytes!} B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(2)} KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
