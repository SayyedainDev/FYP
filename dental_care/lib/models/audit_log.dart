import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String userId;
  final String
      action; // 'create', 'update', 'delete', 'view', 'login', 'logout'
  final String entityType; // 'patient', 'case', 'appointment', 'treatment_plan'
  final String entityId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String ipAddress;
  final DateTime timestamp;
  final String status; // 'success', 'failed', 'pending'

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValue,
    this.newValue,
    required this.ipAddress,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'oldValue': oldValue,
      'newValue': newValue,
      'ipAddress': ipAddress,
      'timestamp': timestamp,
      'status': status,
    };
  }

  static AuditLog fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      oldValue: data['oldValue'],
      newValue: data['newValue'],
      ipAddress: data['ipAddress'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'success',
    );
  }
}
