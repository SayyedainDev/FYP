import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String instructorId;
  final String title;
  final String description;
  final String subject;
  final DateTime dueDate;
  final double totalMarks;
  final List<String> assignedTo; // Student IDs
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fileUrl;
  final String storagePath;
  final String status; // Active, Closed, Archived

  Assignment({
    required this.id,
    required this.instructorId,
    required this.title,
    required this.description,
    required this.subject,
    required this.dueDate,
    required this.totalMarks,
    required this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.fileUrl,
    required this.storagePath,
    required this.status,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toFirestore() {
    return {
      'instructorId': instructorId,
      'title': title,
      'description': description,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'totalMarks': totalMarks,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'status': status,
    };
  }

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      instructorId: data['instructorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalMarks: (data['totalMarks'] ?? 0).toDouble(),
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileUrl: data['fileUrl'] ?? '',
      storagePath: data['storagePath'] ?? '',
      status: data['status'] ?? 'Active',
    );
  }
}
