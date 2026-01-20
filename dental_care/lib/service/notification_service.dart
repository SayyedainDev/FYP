import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final List<AppNotification> _notifications = [];

  void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(message, NotificationType.success, duration);
  }

  void showError(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(message, NotificationType.error, duration);
  }

  void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(message, NotificationType.warning, duration);
  }

  void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(message, NotificationType.info, duration);
  }

  void _showNotification(
    String message,
    NotificationType type,
    Duration duration,
  ) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    _notifications.add(notification);

    // Auto remove after duration
    Future.delayed(duration, () {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  List<AppNotification> getNotifications() => List.unmodifiable(_notifications);
}

enum NotificationType { success, error, warning, info }

class AppNotification {
  final String id;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  Color get backgroundColor {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }
}
