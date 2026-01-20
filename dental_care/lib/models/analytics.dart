class AnalyticsData {
  final int totalPatients;
  final int totalCases;
  final int cavitiesDetected;
  final int healthyCases;
  final double cavityDetectionRate;
  final int appointmentsThisMonth;
  final int appointmentsCompleted;
  final double appointmentCompletionRate;
  final List<MonthlyData> monthlyTrends;
  final List<ToothAnalysis> toothWiseAnalysis;
  final double averageCaseResolutionTime; // in days
  final Map<String, int> casesByStatus;
  final Map<String, int> casesByType;
  final int patientRetentionRate; // percentage

  AnalyticsData({
    required this.totalPatients,
    required this.totalCases,
    required this.cavitiesDetected,
    required this.healthyCases,
    required this.cavityDetectionRate,
    required this.appointmentsThisMonth,
    required this.appointmentsCompleted,
    required this.appointmentCompletionRate,
    required this.monthlyTrends,
    required this.toothWiseAnalysis,
    required this.averageCaseResolutionTime,
    required this.casesByStatus,
    required this.casesByType,
    required this.patientRetentionRate,
  });
}

class MonthlyData {
  final String month; // 'Jan', 'Feb', etc.
  final int cases;
  final int patients;
  final int cavitiesDetected;
  final double revenue;

  MonthlyData({
    required this.month,
    required this.cases,
    required this.patients,
    required this.cavitiesDetected,
    required this.revenue,
  });
}

class ToothAnalysis {
  final String toothNumber;
  final String toothName;
  final int casesFound;
  final double detectionFrequency;
  final String mostCommonIssue;
  final double treatmentSuccessRate;

  ToothAnalysis({
    required this.toothNumber,
    required this.toothName,
    required this.casesFound,
    required this.detectionFrequency,
    required this.mostCommonIssue,
    required this.treatmentSuccessRate,
  });
}
