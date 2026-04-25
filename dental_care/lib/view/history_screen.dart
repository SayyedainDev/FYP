import 'package:dental_care/models/case.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/case_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/loaders/app_loader.dart';
import 'widgets/create_case_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _statusOptions = [
    'Uploaded',
    'Under Review',
    'Completed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _patientNameFor(Case c, PatientProvider patientProvider) {
    final fromProvider = patientProvider.getPatientById(c.patientId)?.name;
    if (fromProvider != null && fromProvider.trim().isNotEmpty) {
      return fromProvider.trim();
    }
    final fallback = c.patientName.trim();
    if (fallback.isNotEmpty && !fallback.toLowerCase().startsWith('case ')) {
      return fallback;
    }
    return 'Patient';
  }

  String _toothLabel(Case c) {
    if (c.toothNumber.trim().isEmpty) return 'Not specified';
    return c.toothNumber;
  }

  Color _statusColor(ColorScheme cs, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'under review':
        return Colors.orange.shade700;
      default:
        return cs.primary;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _pickStartDate(
      BuildContext context, CaseProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.filterStartDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) provider.setStartDateFilter(picked);
  }

  Future<void> _pickEndDate(BuildContext context, CaseProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.filterEndDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      provider.setEndDateFilter(
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
      );
    }
  }

  Future<void> _updateCaseStatus(
    BuildContext context,
    CaseProvider provider,
    Case caseItem,
    String nextStatus,
  ) async {
    final ok = await provider.updateCase(caseItem.id, {
      'caseStatus': nextStatus,
    });
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Case status updated to $nextStatus'
            : 'Failed to update case status'),
      ),
    );
  }

  Future<void> _deleteCase(
    BuildContext context,
    CaseProvider provider,
    Case caseItem,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Case'),
        content: const Text('This action cannot be undone. Delete this case?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await provider.deleteCase(caseItem.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? 'Case deleted' : 'Failed to delete case')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final cases = caseProvider.cases;
    final completedCount =
        cases.where((c) => c.caseStatus.toLowerCase() == 'completed').length;
    final reviewCount =
        cases.where((c) => c.caseStatus.toLowerCase() == 'under review').length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header actions (title is provided by layout app bar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track patient cases, monitor condition, and manage treatment workflow.',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use filters to quickly find affected teeth, diagnosis status, and treatment progress.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const CreateCaseDialog(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Case'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(
                  title: 'Total Cases',
                  value: '${cases.length}',
                  icon: Icons.folder_open,
                ),
                _SummaryCard(
                  title: 'Under Review',
                  value: '$reviewCount',
                  icon: Icons.pending_actions,
                ),
                _SummaryCard(
                  title: 'Completed',
                  value: '$completedCount',
                  icon: Icons.verified,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            _FilterRow(
              caseProvider: caseProvider,
              patientProvider: patientProvider,
              searchController: _searchController,
              statusOptions: _statusOptions,
              onPickStartDate: () => _pickStartDate(context, caseProvider),
              onPickEndDate: () => _pickEndDate(context, caseProvider),
            ),
            const SizedBox(height: 24),

            // Content
            if (caseProvider.loading)
              const SizedBox(
                height: 300,
                child: Center(
                  child: AppLoader(
                    message: 'Loading scan history...',
                  ),
                ),
              )
            else if (caseProvider.error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'An error occurred while loading scan history. Please try again.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.onError),
                      ),
                    ),
                  ],
                ),
              )
            else if (caseProvider.cases.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 48, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 10),
                    Text(
                      'No scan history found',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try changing filters or add a new case.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: caseProvider.cases.length,
                itemBuilder: (context, index) {
                  final caseItem = caseProvider.cases[index];
                  final patientName =
                      _patientNameFor(caseItem, patientProvider);
                  final condition = caseItem.isAnalysisComplete
                      ? caseItem.cavityStatus
                      : caseItem.analysisStatus;
                  final statusColor =
                      _statusColor(colorScheme, caseItem.caseStatus);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${_formatDate(caseItem.caseDate)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Case actions',
                              onSelected: (value) async {
                                if (value == 'copy_id') {
                                  await Clipboard.setData(
                                    ClipboardData(text: caseItem.id),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Case ID copied')),
                                  );
                                } else if (value == 'uploaded') {
                                  await _updateCaseStatus(context, caseProvider,
                                      caseItem, 'Uploaded');
                                } else if (value == 'review') {
                                  await _updateCaseStatus(context, caseProvider,
                                      caseItem, 'Under Review');
                                } else if (value == 'completed') {
                                  await _updateCaseStatus(context, caseProvider,
                                      caseItem, 'Completed');
                                } else if (value == 'delete') {
                                  await _deleteCase(
                                      context, caseProvider, caseItem);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'uploaded',
                                  child: Text('Mark as Uploaded'),
                                ),
                                PopupMenuItem(
                                  value: 'review',
                                  child: Text('Mark as Under Review'),
                                ),
                                PopupMenuItem(
                                  value: 'completed',
                                  child: Text('Mark as Completed'),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'copy_id',
                                  child: Text('Copy Case ID'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Case'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _CaseChip(
                              icon: Icons.tag,
                              label: 'Tooth ${_toothLabel(caseItem)}',
                              background: colorScheme.secondaryContainer,
                              foreground: colorScheme.onSecondaryContainer,
                            ),
                            _CaseChip(
                              icon: Icons.medical_information,
                              label: 'Condition: $condition',
                              background: colorScheme.tertiaryContainer,
                              foreground: colorScheme.onTertiaryContainer,
                            ),
                            _CaseChip(
                              icon: Icons.flag,
                              label: 'Status: ${caseItem.caseStatus}',
                              background: statusColor.withValues(alpha: 0.12),
                              foreground: statusColor,
                            ),
                          ],
                        ),
                        if (caseItem.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            caseItem.notes,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final CaseProvider caseProvider;
  final PatientProvider patientProvider;
  final TextEditingController searchController;
  final List<String> statusOptions;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;

  const _FilterRow({
    required this.caseProvider,
    required this.patientProvider,
    required this.searchController,
    required this.statusOptions,
    required this.onPickStartDate,
    required this.onPickEndDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    searchController.value = TextEditingValue(
      text: caseProvider.searchQuery,
      selection:
          TextSelection.collapsed(offset: caseProvider.searchQuery.length),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String?>(
              initialValue: caseProvider.filterPatientId,
              decoration: const InputDecoration(
                labelText: 'Patient',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Patients'),
                ),
                ...patientProvider.patients.map(
                  (p) => DropdownMenuItem<String?>(
                    value: p.id,
                    child: Text(p.name),
                  ),
                ),
              ],
              onChanged: caseProvider.setPatientFilter,
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              initialValue: caseProvider.filterCaseStatus,
              decoration: const InputDecoration(
                labelText: 'Case Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...statusOptions.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s,
                    child: Text(s),
                  ),
                ),
              ],
              onChanged: caseProvider.setCaseStatusFilter,
            ),
          ),
          SizedBox(
            width: 180,
            child: OutlinedButton.icon(
              onPressed: onPickStartDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                caseProvider.filterStartDate == null
                    ? 'Start Date'
                    : _formatDate(caseProvider.filterStartDate!),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: OutlinedButton.icon(
              onPressed: onPickEndDate,
              icon: const Icon(Icons.event),
              label: Text(
                caseProvider.filterEndDate == null
                    ? 'End Date'
                    : _formatDate(caseProvider.filterEndDate!),
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: TextFormField(
              controller: searchController,
              onChanged: caseProvider.setSearchQuery,
              decoration: InputDecoration(
                labelText: 'Search patient, tooth, condition, status',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: caseProvider.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          caseProvider.setSearchQuery('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: FilledButton.tonalIcon(
              onPressed: () {
                searchController.clear();
                caseProvider.clearFilters();
              },
              icon: const Icon(Icons.close),
              label: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                title,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaseChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _CaseChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
