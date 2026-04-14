import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';
import '../utils/provider_error_utils.dart';

class AuditLogProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AuditLog> _logs = [];
  bool _loading = false;
  String? _error;

  List<AuditLog> get logs => List.unmodifiable(_logs);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAuditLogs(String dentistUid, {int limit = 100}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('audit_logs')
          .where('userId', isEqualTo: dentistUid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      _logs =
          querySnapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to fetch audit logs. Please try again.',
      );
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching audit logs: $e');
    }
  }

  Future<void> logAction({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    required String ipAddress,
    String status = 'success',
  }) async {
    try {
      final docId = _firestore.collection('audit_logs').doc().id;
      final log = AuditLog(
        id: docId,
        userId: userId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        oldValue: oldValue,
        newValue: newValue,
        ipAddress: ipAddress,
        timestamp: DateTime.now(),
        status: status,
      );

      await _firestore
          .collection('audit_logs')
          .doc(docId)
          .set(log.toFirestore())
          .timeout(ProviderErrorUtils.requestTimeout);

      _logs.insert(0, log);
      notifyListeners();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to record audit log. Please try again.',
      );
      notifyListeners();
      debugPrint('Error logging action: $e');
    }
  }

  List<AuditLog> getLogsByEntity(String entityType, String entityId) {
    return _logs
        .where(
          (log) => log.entityType == entityType && log.entityId == entityId,
        )
        .toList();
  }

  List<AuditLog> getLogsByAction(String action) {
    return _logs.where((log) => log.action == action).toList();
  }

  List<AuditLog> getLogsByDateRange(DateTime start, DateTime end) {
    return _logs
        .where(
          (log) => log.timestamp.isAfter(start) && log.timestamp.isBefore(end),
        )
        .toList();
  }
}
