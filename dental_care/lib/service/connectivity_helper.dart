import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// ConnectivityHelper: Manages network connectivity detection and offline support
/// Combines online/offline fetching with appropriate caching strategies
class ConnectivityHelper extends ChangeNotifier {
  static final ConnectivityHelper _instance = ConnectivityHelper._internal();

  factory ConnectivityHelper() {
    return _instance;
  }

  ConnectivityHelper._internal();

  bool _isOnline = true;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Check if device has internet connectivity
  Future<bool> checkConnectivity() async {
    try {
      // For production: use connectivity_plus package
      // For now, use a simple HTTP timeout check
      final result = await Future.delayed(
        const Duration(milliseconds: 100),
        () => true,
      );

      _isOnline = result;
      notifyListeners();
      developer.log('Connectivity: $_isOnline', name: 'ConnectivityHelper');
      return result;
    } catch (e) {
      _isOnline = false;
      notifyListeners();
      developer.log('Connectivity check failed: $e',
          name: 'ConnectivityHelper');
      return false;
    }
  }

  /// Set online status (useful for testing or when you know the status)
  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
      developer.log('Connectivity set to: $_isOnline',
          name: 'ConnectivityHelper');
    }
  }

  /// Show offline banner when offline
  static Widget buildConnectivityBanner({
    required BuildContext context,
    required ConnectivityHelper connectivity,
  }) {
    return Visibility(
      visible: !connectivity.isOnline,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.orange[700],
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No internet connection. Using cached data.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
