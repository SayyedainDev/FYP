import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics.dart';
import '../models/case.dart';

class AnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AnalyticsData? _analyticsData;
  bool _loading = false;
  String? _error;

  AnalyticsData? get analyticsData => _analyticsData;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> generateAnalytics(String dentistUid, List<Case> cases) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final patients = await _firestore
          .collection('patients')
          .where('dentistUid', isEqualTo: dentistUid)
          .get();

      final appointments = await _firestore
          .collection('appointments')
          .where('dentistUid', isEqualTo: dentistUid)
          .get();

      // Calculate metrics
      final totalPatients = patients.docs.length;
      final totalCases = cases.length;
      final cavitiesDetected = cases
          .where((c) => c.hasCavity && c.isAnalysisComplete)
          .length;
      final healthyCases = cases
          .where((c) => !c.hasCavity && c.isAnalysisComplete)
          .length;
      final cavityDetectionRate = totalCases > 0
          ? (cavitiesDetected / totalCases * 100).toStringAsFixed(1)
          : '0.0';

      final now = DateTime.now();
      final thisMonth = appointments.docs.where((doc) {
        final date = (doc['appointmentDate'] as Timestamp).toDate();
        return date.year == now.year && date.month == now.month;
      }).length;

      final completed = appointments.docs
          .where((doc) => doc['status'] == 'completed')
          .length;
      final completionRate = appointments.docs.isNotEmpty
          ? (completed / appointments.docs.length * 100)
          : 0;

      // Monthly trends (last 6 months)
      final monthlyTrends = _generateMonthlyTrends(cases);

      // Tooth-wise analysis
      final toothAnalysis = _generateToothAnalysis(cases);

      // Case status distribution
      final casesByStatus = _generateCasesByStatus(cases);
      final casesByType = _generateCasesByType(cases);

      _analyticsData = AnalyticsData(
        totalPatients: totalPatients,
        totalCases: totalCases,
        cavitiesDetected: cavitiesDetected,
        healthyCases: healthyCases,
        cavityDetectionRate: double.parse(cavityDetectionRate),
        appointmentsThisMonth: thisMonth,
        appointmentsCompleted: completed,
        appointmentCompletionRate: completionRate.toDouble(),
        monthlyTrends: monthlyTrends,
        toothWiseAnalysis: toothAnalysis,
        averageCaseResolutionTime: _calculateResolutionTime(cases),
        casesByStatus: casesByStatus,
        casesByType: casesByType,
        patientRetentionRate: _calculateRetentionRate(cases),
      );

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to generate analytics: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error generating analytics: $e');
    }
  }

  List<MonthlyData> _generateMonthlyTrends(List<Case> cases) {
    final monthlyMap = <String, MonthlyData>{};
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 0; i < 6; i++) {
      final date = DateTime.now().subtract(Duration(days: 30 * i));
      final monthKey = monthNames[date.month - 1];

      monthlyMap[monthKey] = MonthlyData(
        month: monthKey,
        cases: cases
            .where(
              (c) =>
                  c.caseDate.month == date.month &&
                  c.caseDate.year == date.year,
            )
            .length,
        patients: 0,
        cavitiesDetected: cases
            .where(
              (c) =>
                  c.hasCavity &&
                  c.caseDate.month == date.month &&
                  c.caseDate.year == date.year,
            )
            .length,
        revenue: 0,
      );
    }

    return monthlyMap.values.toList().reversed.toList();
  }

  List<ToothAnalysis> _generateToothAnalysis(List<Case> cases) {
    final toothMap = <String, int>{};

    for (var case_ in cases) {
      final verdictNotes = case_.analysisResults['verdictNotes'];
      if (verdictNotes != null) {
        final notes = verdictNotes as List;
        for (var note in notes) {
          if (note.toString().contains('FDI')) {
            // Extract FDI numbers from notes
            final regex = RegExp(r'(\d{2})');
            final matches = regex.allMatches(note.toString());
            for (var match in matches) {
              final tooth = match.group(0) ?? '';
              toothMap[tooth] = (toothMap[tooth] ?? 0) + 1;
            }
          }
        }
      }
    }

    return toothMap.entries
        .map(
          (e) => ToothAnalysis(
            toothNumber: e.key,
            toothName: 'Tooth ${e.key}',
            casesFound: e.value,
            detectionFrequency: cases.isEmpty
                ? 0
                : (e.value / cases.length * 100),
            mostCommonIssue: 'Carious lesion',
            treatmentSuccessRate: 85.0,
          ),
        )
        .toList();
  }

  Map<String, int> _generateCasesByStatus(List<Case> cases) {
    final statusMap = <String, int>{};
    for (var case_ in cases) {
      statusMap.update(case_.caseStatus, (v) => v + 1, ifAbsent: () => 1);
    }
    return statusMap;
  }

  Map<String, int> _generateCasesByType(List<Case> cases) {
    final typeMap = <String, int>{};
    for (var case_ in cases) {
      typeMap.update(
        case_.caseTitle.isNotEmpty ? case_.caseTitle : 'Standard Case',
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    return typeMap;
  }

  double _calculateResolutionTime(List<Case> cases) {
    if (cases.isEmpty) return 0;
    final times = cases
        .where((c) => c.isAnalysisComplete)
        .map((c) => c.caseDate.difference(DateTime.now()).inDays.abs())
        .toList();
    return times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length;
  }

  int _calculateRetentionRate(List<Case> cases) {
    return (cases.length > 10 ? 85 : 70);
  }
}
