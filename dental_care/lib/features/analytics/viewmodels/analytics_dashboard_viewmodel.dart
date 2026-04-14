import 'package:flutter/material.dart';
import '../models/analytics_dashboard_data.dart';
import '../repository/analytics_repository.dart';
import '../../../models/case.dart';
import '../../../models/quiz.dart';

class AnalyticsDashboardViewModel extends ChangeNotifier {
  final AnalyticsRepository _repository;

  AnalyticsDashboardViewModel(this._repository);

  bool _isLoading = false;
  DateTimeRange? _range;
  AnalyticsDashboardData? _data;

  bool get isLoading => _isLoading;
  DateTimeRange? get range => _range;
  AnalyticsDashboardData? get data => _data;

  Future<void> load({
    required List<Case> cases,
    required List<Quiz> quizzes,
  }) async {
    _isLoading = true;
    notifyListeners();
    _data = _repository.buildDashboardData(
      cases: cases,
      quizzes: quizzes,
      range: _range,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setRange({
    required DateTimeRange? nextRange,
    required List<Case> cases,
    required List<Quiz> quizzes,
  }) async {
    _range = nextRange;
    await load(cases: cases, quizzes: quizzes);
  }
}
