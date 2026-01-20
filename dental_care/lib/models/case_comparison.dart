class CaseComparison {
  final String caseId1;
  final String caseId2;
  final String patientId;
  final DateTime date1;
  final DateTime date2;
  final int daysBetween;
  final List<String> improvements; // List of improvements
  final List<String> newFindings; // New issues found
  final List<String> resolvedIssues; // Issues that resolved
  final double progressScore; // 0-100
  final String overallStatus; // 'improved', 'stable', 'declined'
  final String analysis; // Text analysis of comparison

  CaseComparison({
    required this.caseId1,
    required this.caseId2,
    required this.patientId,
    required this.date1,
    required this.date2,
    required this.daysBetween,
    required this.improvements,
    required this.newFindings,
    required this.resolvedIssues,
    required this.progressScore,
    required this.overallStatus,
    required this.analysis,
  });
}
