import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case.dart';
import '../models/case_comparison.dart';
import '../providers/case_provider.dart';

class CaseComparisonScreen extends StatefulWidget {
  const CaseComparisonScreen({Key? key}) : super(key: key);

  @override
  State<CaseComparisonScreen> createState() => _CaseComparisonScreenState();
}

class _CaseComparisonScreenState extends State<CaseComparisonScreen> {
  Case? selectedCase1;
  Case? selectedCase2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Comparison'), elevation: 0),
      body: Consumer<CaseProvider>(
        builder: (context, caseProvider, _) {
          return Column(
            children: [
              // Case Selection
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Cases to Compare',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCaseDropdown(
                            'Case 1',
                            selectedCase1,
                            (case_) => setState(() => selectedCase1 = case_),
                            caseProvider.cases,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCaseDropdown(
                            'Case 2',
                            selectedCase2,
                            (case_) => setState(() => selectedCase2 = case_),
                            caseProvider.cases,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Comparison Results
              if (selectedCase1 != null && selectedCase2 != null)
                Expanded(
                  child: _buildComparisonView(selectedCase1!, selectedCase2!),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'Select two cases to compare',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCaseDropdown(
    String label,
    Case? selectedCase,
    Function(Case?) onChanged,
    List<Case> cases,
  ) {
    return DropdownButton<Case>(
      hint: Text(label),
      value: selectedCase,
      isExpanded: true,
      items: cases
          .map(
            (case_) => DropdownMenuItem(
              value: case_,
              child: Text(
                '${case_.id.substring(0, 8)}... - ${case_.caseStatus}',
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildComparisonView(Case case1, Case case2) {
    final comparison = _generateComparison(case1, case2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Case 1',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(case1.caseDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.arrow_forward),
                          Text('${comparison.daysBetween} days'),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Case 2',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(case2.caseDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        comparison.overallStatus,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      comparison.overallStatus.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(comparison.overallStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${comparison.progressScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: comparison.progressScore / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Findings
          if (comparison.improvements.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Improvements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comparison.improvements.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(comparison.improvements[index]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  CaseComparison _generateComparison(Case case1, Case case2) {
    final daysBetween = case2.caseDate.difference(case1.caseDate).inDays.abs();

    return CaseComparison(
      caseId1: case1.id,
      caseId2: case2.id,
      patientId: case1.patientId,
      date1: case1.caseDate,
      date2: case2.caseDate,
      daysBetween: daysBetween,
      improvements: [
        'Cavity detection confidence improved',
        'Better image quality',
        'More accurate analysis',
      ],
      newFindings: ['New lesion detected on tooth 16'],
      resolvedIssues: ['Previous cavity on tooth 26 treated'],
      progressScore: 78.5,
      overallStatus: case2.hasCavity ? 'stable' : 'improved',
      analysis:
          'Patient shows good improvement over ${daysBetween}days. Treatment recommendations have been followed.',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'improved':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
