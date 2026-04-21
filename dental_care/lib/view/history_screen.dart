import 'package:dental_care/models/case.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/case_provider.dart';
import 'widgets/create_case_dialog.dart';
import '../providers/patient_provider.dart';
import '../core/theme/app_semantic_colors.dart';
import '../utils/app_dialogs.dart';
import '../widgets/loaders/app_loader.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan History',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and review patient scans',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const CreateCaseDialog(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Case'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            _FilterRow(
              caseProvider: caseProvider,
              patientProvider: patientProvider,
            ),
            const SizedBox(height: 24),

            // Content
            if (caseProvider.loading)
              SizedBox(
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
                        caseProvider.error!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              )
            else if (caseProvider.cases.isEmpty)
              _EmptyState()
            else
              Column(
                children: caseProvider.cases
                    .map((c) => _CaseHistoryCard(caseItem: c))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new case to get started',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatefulWidget {
  const _FilterRow({required this.caseProvider, required this.patientProvider});

  final CaseProvider caseProvider;
  final PatientProvider patientProvider;

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.caseProvider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary filters
          Row(
            children: [
              Expanded(
                child: _PatientDropdown(
                  caseProvider: widget.caseProvider,
                  patientProvider: widget.patientProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CaseStatusDropdown(caseProvider: widget.caseProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date range filters
          Row(
            children: [
              Expanded(
                child: _DatePicker(
                  label: 'Start Date',
                  date: widget.caseProvider.filterStartDate,
                  onChanged: widget.caseProvider.setStartDateFilter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePicker(
                  label: 'End Date',
                  date: widget.caseProvider.filterEndDate,
                  onChanged: widget.caseProvider.setEndDateFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search and clear
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by patient, title, or tooth number',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: widget.caseProvider.setSearchQuery,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () {
                  _searchController.clear();
                  widget.caseProvider.clearFilters();
                },
                child: const Row(
                  children: [
                    Icon(Icons.clear, size: 18),
                    SizedBox(width: 8),
                    Text('Clear'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    final patients = patientProvider.patients;
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Patient',
        prefixIcon: Icon(Icons.person),
      ),
      value: caseProvider.filterPatientId,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Patients'),
        ),
        ...patients.map(
          (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
        ),
      ],
      onChanged: caseProvider.setPatientFilter,
    );
  }
}

class _CaseStatusDropdown extends StatelessWidget {
  const _CaseStatusDropdown({required this.caseProvider});

  final CaseProvider caseProvider;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Case Status',
        prefixIcon: Icon(Icons.analytics),
      ),
      value: caseProvider.filterCaseStatus,
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('All Cases')),
        DropdownMenuItem<String?>(value: 'Uploaded', child: Text('Uploaded')),
        DropdownMenuItem<String?>(
          value: 'Under Review',
          child: Text('Under Review'),
        ),
        DropdownMenuItem<String?>(value: 'Completed', child: Text('Completed')),
      ],
      onChanged: caseProvider.setCaseStatusFilter,
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
    final colorScheme = Theme.of(context).colorScheme;
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
            color: date != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final isAnalysisComplete = caseItem.isAnalysisComplete;
    final hasCavity = caseItem.hasCavity;
    final status = caseItem.caseStatus;

    // Status styling
    Color statusColor;
    Color statusBg;
    if (status == 'Completed') {
      statusColor = semanticColors?.success ?? Colors.green;
      statusBg =
          (semanticColors?.success ?? Colors.green).withValues(alpha: 0.12);
    } else if (status == 'Under Review') {
      statusColor = semanticColors?.info ?? colorScheme.primary;
      statusBg =
          (semanticColors?.info ?? colorScheme.primary).withValues(alpha: 0.12);
    } else if (status == 'Archived') {
      statusColor = colorScheme.onSurfaceVariant;
      statusBg = colorScheme.surfaceContainerHighest;
    } else {
      statusColor = semanticColors?.warning ?? Colors.orange;
      statusBg =
          (semanticColors?.warning ?? Colors.orange).withValues(alpha: 0.12);
    }

    // Analysis styling
    final analysisLabel = !isAnalysisComplete
        ? 'Pending Analysis'
        : hasCavity
            ? 'Cavity Detected'
            : 'Healthy';
    final analysisColor = !isAnalysisComplete
        ? semanticColors?.info ?? colorScheme.primary
        : hasCavity
            ? semanticColors?.danger ?? Colors.red
            : semanticColors?.success ?? Colors.green;
    final analysisBg = !isAnalysisComplete
        ? (semanticColors?.info ?? colorScheme.primary).withValues(alpha: 0.12)
        : hasCavity
            ? (semanticColors?.danger ?? Colors.red).withValues(alpha: 0.12)
            : (semanticColors?.success ?? Colors.green).withValues(alpha: 0.12);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: analysisBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                !isAnalysisComplete
                    ? Icons.hourglass_empty
                    : hasCavity
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                color: analysisColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (caseItem.caseTitle.isNotEmpty)
                    Text(
                      caseItem.caseTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: statusBg,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(
                          analysisLabel,
                          style: TextStyle(
                            color: analysisColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: analysisBg,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(caseItem.caseDate),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (caseItem.toothNumber.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.medical_services_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tooth #${caseItem.toothNumber}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (caseItem.imageUrls.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${caseItem.imageUrls.length} image(s)',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Notes preview
                  if (caseItem.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      caseItem.notes,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            SizedBox(
              width: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'View Details',
                    child: IconButton(
                      icon: Icon(Icons.info_outline,
                          color: colorScheme.primary, size: 20),
                      onPressed: () => _showCaseDetails(context, caseItem),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  if (caseItem.imageUrls.isNotEmpty)
                    Tooltip(
                      message: 'View Images',
                      child: IconButton(
                        icon: Icon(Icons.image_outlined,
                            color: colorScheme.primary, size: 20),
                        onPressed: () => _showCaseImages(context, caseItem),
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  Tooltip(
                    message: 'Download Report',
                    child: IconButton(
                      icon: Icon(Icons.download_outlined,
                          color: colorScheme.primary, size: 20),
                      onPressed: () => _downloadReport(context, caseItem),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: colorScheme.onSurfaceVariant, size: 20),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      if (caseItem.caseStatus != 'Archived')
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined,
                                  size: 18,
                                  color:
                                      semanticColors?.warning ?? Colors.orange),
                              const SizedBox(width: 12),
                              const Text('Archive'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outlined,
                                size: 18, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Text('Delete',
                                style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editCase(context, caseItem);
                          break;
                        case 'archive':
                          _archiveCase(context, caseItem);
                          break;
                        case 'delete':
                          _deleteCase(context, caseItem);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCaseDetails(BuildContext context, Case caseItem) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Case Information',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content
              SingleChildScrollView(
                child: Column(
                  children: [
                    _DetailItemRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDateTime(caseItem.caseDate),
                    ),
                    const SizedBox(height: 12),
                    if (caseItem.toothNumber.isNotEmpty)
                      _DetailItemRow(
                        icon: Icons.medical_services_outlined,
                        label: 'Tooth',
                        value: 'FDI #${caseItem.toothNumber}',
                      ),
                    if (caseItem.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailItemRow(
                        icon: Icons.image_outlined,
                        label: 'Images',
                        value: '${caseItem.imageUrls.length} X-ray(s)',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _DetailItemRow(
                      icon: Icons.analytics_outlined,
                      label: 'Analysis',
                      value: caseItem.analysisStatus,
                    ),
                    if (caseItem.isAnalysisComplete) ...[
                      const SizedBox(height: 12),
                      _DetailItemRow(
                        icon: caseItem.hasCavity
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        label: 'Result',
                        value: caseItem.hasCavity
                            ? 'Cavity Detected'
                            : 'Healthy/Pending',
                        valueColor: caseItem.hasCavity
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                    ],
                    if (caseItem.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note_outlined,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Text(
                                'Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              caseItem.notes,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCaseImages(BuildContext context, Case caseItem) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'X-ray Images',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Images grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: caseItem.imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(
                          context, caseItem.imageUrls[index]),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                caseItem.imageUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: AppLoader(size: 32),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: AppLoader(size: 48));
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context, Case caseItem) async {
    try {
      final doc = pw.Document();
      final dateText = _formatDateTime(caseItem.caseDate);

      doc.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Dental Case Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 12),
                _buildPdfRow('Case ID', caseItem.id),
                if (caseItem.caseTitle.isNotEmpty)
                  _buildPdfRow('Title', caseItem.caseTitle),
                _buildPdfRow('Date', dateText),
                if (caseItem.toothNumber.isNotEmpty)
                  _buildPdfRow('Tooth Number', 'FDI #${caseItem.toothNumber}'),
                _buildPdfRow('Status', caseItem.caseStatus),
                _buildPdfRow('Analysis Status', caseItem.analysisStatus),
                if (caseItem.isAnalysisComplete)
                  _buildPdfRow(
                    'Result',
                    caseItem.hasCavity ? 'Cavity Detected' : 'Healthy',
                  ),
                _buildPdfRow('Images', '${caseItem.imageUrls.length} X-ray(s)'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(caseItem.notes.isNotEmpty ? caseItem.notes : '—'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Review Notes',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  caseItem.reviewNotes.isNotEmpty
                      ? caseItem.reviewNotes
                      : 'Pending',
                ),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'case_${caseItem.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Failed to generate report. Please try again.',
        );
      }
    }
  }

  void _editCase(BuildContext context, Case caseItem) {
    final titleController = TextEditingController(text: caseItem.caseTitle);
    final notesController = TextEditingController(text: caseItem.notes);
    final reviewController = TextEditingController(text: caseItem.reviewNotes);
    String selectedStatus = caseItem.caseStatus;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Case',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Case Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items:
                          ['Uploaded', 'Under Review', 'Completed', 'Archived']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) selectedStatus = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        labelText: 'Review Notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final caseProvider = Provider.of<CaseProvider>(
                        context,
                        listen: false,
                      );
                      final success =
                          await caseProvider.updateCase(caseItem.id, {
                        'caseTitle': titleController.text,
                        'caseStatus': selectedStatus,
                        'notes': notesController.text,
                        'reviewNotes': reviewController.text,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          AppDialogs.showInfoDialog(context,
                              title: 'Success',
                              message: 'Case updated successfully');
                        } else {
                          AppDialogs.showErrorDialog(context,
                              message: 'Failed to update case.');
                        }
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _archiveCase(BuildContext context, Case caseItem) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Archive Case'),
        content: const Text(
            'Are you sure you want to archive this case? It will be moved to the archive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final caseProvider = Provider.of<CaseProvider>(
                context,
                listen: false,
              );
              final success = await caseProvider.archiveCase(caseItem.id);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  AppDialogs.showInfoDialog(context,
                      title: 'Success', message: 'Case archived successfully');
                } else {
                  AppDialogs.showErrorDialog(context,
                      message: 'Failed to archive case.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: semanticColors?.warning ?? Colors.orange,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _deleteCase(BuildContext context, Case caseItem) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Are you sure you want to permanently delete this case?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This action cannot be undone. All images will be permanently deleted.',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final caseProvider = Provider.of<CaseProvider>(
                context,
                listen: false,
              );
              final success = await caseProvider.deleteCase(caseItem.id);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  AppDialogs.showInfoDialog(context,
                      title: 'Success', message: 'Case deleted successfully');
                } else {
                  AppDialogs.showErrorDialog(context,
                      message: 'Failed to delete case.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: semanticColors?.danger ?? colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  const _DetailItemRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
