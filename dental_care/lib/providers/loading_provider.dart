import 'package:flutter/material.dart';

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Helper template for running async tasks securely
  Future<void> runAsyncAction(Future<void> Function() action) async {
    if (_isLoading) return; // Prevent concurrent presses
    setLoading(true);
    try {
      await action();
    } finally {
      if (_isLoading) {
        setLoading(false);
      }
    }
  }
}
