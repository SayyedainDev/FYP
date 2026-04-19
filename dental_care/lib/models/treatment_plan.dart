import 'package:cloud_firestore/cloud_firestore.dart';

class TreatmentPlan {
  final String id;
  final String patientId;
  final String dentistUid;
  final String title;
  final String description;
  final List<TreatmentPhase> phases;
  final String status; // 'draft', 'active', 'completed', 'on-hold'
  final DateTime startDate;
  final DateTime? completionDate;
  final double estimatedCost;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final int progressPercentage; // 0-100
  final DateTime createdAt;
  final DateTime updatedAt;

  TreatmentPlan({
    required this.id,
    required this.patientId,
    required this.dentistUid,
    required this.title,
    required this.description,
    required this.phases,
    required this.status,
    required this.startDate,
    this.completionDate,
    required this.estimatedCost,
    required this.priority,
    required this.progressPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'dentistUid': dentistUid,
      'title': title,
      'description': description,
      'phases': phases.map((p) => p.toMap()).toList(),
      'status': status,
      'startDate': startDate,
      'completionDate': completionDate,
      'estimatedCost': estimatedCost,
      'priority': priority,
      'progressPercentage': progressPercentage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static TreatmentPlan fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TreatmentPlan(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      dentistUid: data['dentistUid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      phases: (data['phases'] as List<dynamic>?)
              ?.map((p) => TreatmentPhase.fromMap(p))
              .toList() ??
          [],
      status: data['status'] ?? 'draft',
      startDate: (data['startDate'] as Timestamp).toDate(),
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
      estimatedCost: (data['estimatedCost'] ?? 0).toDouble(),
      priority: data['priority'] ?? 'medium',
      progressPercentage: data['progressPercentage'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}

class TreatmentPhase {
  final String id;
  final String name;
  final String description;
  final int sequenceNumber;
  final DateTime startDate;
  final DateTime dueDate;
  final bool isCompleted;
  final String procedure;
  final double cost;

  TreatmentPhase({
    required this.id,
    required this.name,
    required this.description,
    required this.sequenceNumber,
    required this.startDate,
    required this.dueDate,
    required this.isCompleted,
    required this.procedure,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sequenceNumber': sequenceNumber,
      'startDate': startDate,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
      'procedure': procedure,
      'cost': cost,
    };
  }

  static TreatmentPhase fromMap(Map<String, dynamic> map) {
    return TreatmentPhase(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sequenceNumber: map['sequenceNumber'] ?? 0,
      startDate: (map['startDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
      procedure: map['procedure'] ?? '',
      cost: (map['cost'] ?? 0).toDouble(),
    );
  }
}
