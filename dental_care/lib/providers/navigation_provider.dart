import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  String _currentPage = 'Overview';

  String get currentPage => _currentPage;

  void setPage(String page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListeners();
    }
  }

  bool isActive(String page) => _currentPage == page;
}
