import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  int _selectedTabIndex = 0;

  int get selectedTabIndex => _selectedTabIndex;

  String get selectedTab => _selectedTabIndex == 0 ? 'Dashboard' : 'History';

  void setTab(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void navigateToDashboard() {
    setTab(0);
  }

  void navigateToHistory() {
    setTab(1);
  }
}
