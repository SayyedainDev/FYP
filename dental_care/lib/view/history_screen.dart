import 'package:dental_care/models/case.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/case_provider.dart';
import '../providers/patient_provider.dart';
import '../provider/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCasesForCurrentUser();
    });
  }

  void _loadCasesForCurrentUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);

    // Get current user ID
    String? uid = authProvider.currentUserId ?? authProvider.uid;

    print('Loading cases for UID: $uid'); // Debug log

    if (uid != null) {
      try {
        await caseProvider.fetchCases();
        caseProvider.listenToCases();
      } catch (e) {
        print('Error loading cases: $e'); // Debug log
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Card
              const _FilterCard(),
              const SizedBox(height: 24),

              // Results List
              Consumer<CaseProvider>(
                builder: (context, caseProvider, child) {
                  if (caseProvider.loading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    );
                  }

                  if (caseProvider.cases.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No case history found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload your first scan to see history here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: caseProvider.cases
                        .map((caseItem) => _CaseHistoryCard(caseItem: caseItem))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (Rest of your code is unchanged)

class _FilterCard extends StatelessWidget {
  const _FilterCard();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaseProvider, PatientProvider>(
      builder: (context, caseProvider, patientProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 800;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            child: _PatientDropdown(
                              caseProvider: caseProvider,
                              patientProvider: patientProvider,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _AnalysisStatusDropdown(
                              caseProvider: caseProvider,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DatePicker(
                              label: 'Start Date',
                              date: caseProvider.filterStartDate,
                              onChanged: caseProvider.setStartDateFilter,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DatePicker(
                              label: 'End Date',
                              date: caseProvider.filterEndDate,
                              onChanged: caseProvider.setEndDateFilter,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _PatientDropdown(
                            caseProvider: caseProvider,
                            patientProvider: patientProvider,
                          ),
                          const SizedBox(height: 16),
                          _AnalysisStatusDropdown(caseProvider: caseProvider),
                          const SizedBox(height: 16),
                          _DatePicker(
                            label: 'Start Date',
                            date: caseProvider.filterStartDate,
                            onChanged: caseProvider.setStartDateFilter,
                          ),
                          const SizedBox(height: 16),
                          _DatePicker(
                            label: 'End Date',
                            date: caseProvider.filterEndDate,
                            onChanged: caseProvider.setEndDateFilter,
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: caseProvider.clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PatientDropdown extends StatelessWidget {
  const _PatientDropdown({
    required this.caseProvider,
    required this.patientProvider,
  });

  final CaseProvider caseProvider;
  final PatientProvider patientProvider;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Patient',
        prefixIcon: Icon(Icons.person),
      ),
      value: caseProvider.filterPatientId,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Patients')),
        ...patientProvider.patients.map(
          (patient) =>
              DropdownMenuItem(value: patient.id, child: Text(patient.name)),
        ),
      ],
      onChanged: caseProvider.setPatientFilter,
    );
  }
}

class _AnalysisStatusDropdown extends StatelessWidget {
  const _AnalysisStatusDropdown({required this.caseProvider});

  final CaseProvider caseProvider;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Analysis Status',
        prefixIcon: Icon(Icons.analytics),
      ),
      value: caseProvider.filterAnalysisStatus,
      items: const [
        DropdownMenuItem(value: null, child: Text('All Cases')),
        DropdownMenuItem(value: 'Pending AI Analysis', child: Text('Pending')),
        DropdownMenuItem(value: 'Complete', child: Text('Complete')),
        DropdownMenuItem(value: 'Error', child: Text('Error')),
      ],
      onChanged: caseProvider.setAnalysisStatusFilter,
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          date != null ? _formatDate(date!) : 'Select date',
          style: TextStyle(
            color: date != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _CaseHistoryCard extends StatelessWidget {
  const _CaseHistoryCard({required this.caseItem});

  final Case caseItem;

  @override
  Widget build(BuildContext context) {
    final isAnalysisComplete = caseItem.isAnalysisComplete;
    final hasCavity = caseItem.hasCavity;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !isAnalysisComplete
                    ? Colors.blue.shade100
                    : hasCavity
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                !isAnalysisComplete
                    ? Icons.hourglass_empty
                    : hasCavity
                    ? Icons.warning_amber
                    : Icons.check_circle,
                color: !isAnalysisComplete
                    ? Colors.blue
                    : hasCavity
                    ? Colors.orange
                    : Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),

            // Case Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        caseItem.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(
                          !isAnalysisComplete
                              ? 'Pending Analysis'
                              : hasCavity
                              ? 'Cavity Detected'
                              : 'Healthy',
                          style: TextStyle(
                            color: !isAnalysisComplete
                                ? Colors.blue
                                : hasCavity
                                ? Colors.orange
                                : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: !isAnalysisComplete
                            ? Colors.blue.shade50
                            : hasCavity
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(caseItem.caseDate),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (caseItem.toothNumber.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        Icon(
                          Icons.medical_services,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tooth #${caseItem.toothNumber}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.image, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${caseItem.imageUrls.length} X-ray image(s)',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (caseItem.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      caseItem.notes,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _showCaseDetails(context, caseItem),
                  tooltip: 'View Details',
                ),
                if (caseItem.imageUrls.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () => _showCaseImages(context, caseItem),
                    tooltip: 'View Images',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCaseDetails(BuildContext context, Case caseItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Case Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Patient', caseItem.patientName),
              _DetailRow('Date', _formatDateTime(caseItem.caseDate)),
              if (caseItem.toothNumber.isNotEmpty)
                _DetailRow('Tooth Number', caseItem.toothNumber),
              _DetailRow('Images', '${caseItem.imageUrls.length} X-ray(s)'),
              _DetailRow('Analysis Status', caseItem.analysisStatus),
              if (caseItem.isAnalysisComplete)
                _DetailRow(
                  'Result',
                  caseItem.hasCavity ? 'Cavity Detected' : 'Healthy',
                ),
              if (caseItem.notes.isNotEmpty)
                _DetailRow('Notes', caseItem.notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCaseImages(BuildContext context, Case caseItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('X-ray Images - ${caseItem.patientName}'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: caseItem.imageUrls.length,
            itemBuilder: (context, index) {
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  caseItem.imageUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.grey),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
