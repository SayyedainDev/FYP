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

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan History',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Open create case dialog
                await showDialog(
                  context: context,
                  builder: (context) => const CreateCaseDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Case'),
            ),
          ),
          const SizedBox(height: 16),
          _FilterRow(
            caseProvider: caseProvider,
            patientProvider: patientProvider,
          ),
          const SizedBox(height: 16),
          if (caseProvider.loading)
            const Center(child: AppLoader(message: 'Loading scan history...'))
          else if (caseProvider.error != null)
            Text(
              caseProvider.error!,
              style: TextStyle(
                color: semanticColors?.danger ??
                    Theme.of(context).colorScheme.error,
              ),
            )
          else
            Column(
              children: caseProvider.cases
                  .map((c) => _CaseHistoryCard(caseItem: c))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.caseProvider, required this.patientProvider});

  final CaseProvider caseProvider;
  final PatientProvider patientProvider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PatientDropdown(
                  caseProvider: caseProvider,
                  patientProvider: patientProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _CaseStatusDropdown(caseProvider: caseProvider)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DatePicker(
                  label: 'Start Date',
                  date: caseProvider.filterStartDate,
                  onChanged: caseProvider.setStartDateFilter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePicker(
                  label: 'End Date',
                  date: caseProvider.filterEndDate,
                  onChanged: caseProvider.setEndDateFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: caseProvider.setSearchQuery,
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: caseProvider.clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
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

    Color statusColor;
    Color statusBg;
    if (status == 'Completed') {
      statusColor = semanticColors?.success ?? colorScheme.secondary;
      statusBg = (semanticColors?.success ?? colorScheme.secondary)
          .withValues(alpha: 0.12);
    } else if (status == 'Under Review') {
      statusColor = semanticColors?.info ?? colorScheme.primary;
      statusBg =
          (semanticColors?.info ?? colorScheme.primary).withValues(alpha: 0.12);
    } else {
      statusColor = semanticColors?.warning ?? colorScheme.tertiary;
      statusBg = (semanticColors?.warning ?? colorScheme.tertiary)
          .withValues(alpha: 0.12);
    }

    final analysisLabel = !isAnalysisComplete
        ? 'Pending Analysis'
        : hasCavity
            ? 'Cavity Detected'
            : 'Healthy';
    final analysisColor = !isAnalysisComplete
        ? semanticColors?.info ?? colorScheme.primary
        : hasCavity
            ? semanticColors?.warning ?? colorScheme.tertiary
            : semanticColors?.success ?? colorScheme.secondary;
    final analysisBg = !isAnalysisComplete
        ? (semanticColors?.info ?? colorScheme.primary).withValues(alpha: 0.12)
        : hasCavity
            ? (semanticColors?.warning ?? colorScheme.tertiary)
                .withValues(alpha: 0.12)
            : (semanticColors?.success ?? colorScheme.secondary)
                .withValues(alpha: 0.12);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !isAnalysisComplete
                    ? (semanticColors?.info ?? colorScheme.primary)
                        .withValues(alpha: 0.22)
                    : hasCavity
                        ? (semanticColors?.warning ?? colorScheme.tertiary)
                            .withValues(alpha: 0.22)
                        : (semanticColors?.success ?? colorScheme.secondary)
                            .withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                !isAnalysisComplete
                    ? Icons.hourglass_empty
                    : hasCavity
                        ? Icons.warning_amber
                        : Icons.check_circle,
                color: !isAnalysisComplete
                    ? semanticColors?.info ?? colorScheme.primary
                    : hasCavity
                        ? semanticColors?.warning ?? colorScheme.tertiary
                        : semanticColors?.success ?? colorScheme.secondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caseItem.caseTitle.isNotEmpty) ...[
                    Text(
                      caseItem.caseTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
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
                      ),
                      const SizedBox(width: 8),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(caseItem.caseDate),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      if (caseItem.toothNumber.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        Icon(
                          Icons.medical_services,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tooth #${caseItem.toothNumber}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${caseItem.imageUrls.length} X-ray image(s)',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (caseItem.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      caseItem.notes,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (caseItem.reviewNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Review: ${caseItem.reviewNotes}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
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
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Download report (PDF)',
                  onPressed: () => _downloadReport(context, caseItem),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More actions',
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
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Case'),
                        ],
                      ),
                    ),
                    if (caseItem.caseStatus != 'Archived')
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive, size: 20),
                            SizedBox(width: 8),
                            Text('Archive'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
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
              return GestureDetector(
                onTap: () =>
                    _showFullScreenImage(context, caseItem.imageUrls[index]),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    caseItem.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: AppLoader(size: 36));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.error,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.scrim,
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
                    return const Center(child: AppLoader(size: 42));
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context, Case caseItem) async {
    final doc = pw.Document();
    final dateText = _formatDateTime(caseItem.caseDate);

    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Case Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Case ID: ${caseItem.id}'),
              if (caseItem.caseTitle.isNotEmpty)
                pw.Text('Title: ${caseItem.caseTitle}'),
              pw.Text('Patient: ${caseItem.patientName}'),
              pw.Text('Tooth (FDI): ${caseItem.toothNumber}'),
              pw.Text('Status: ${caseItem.caseStatus}'),
              pw.Text('Analysis: ${caseItem.analysisStatus}'),
              pw.Text(
                'Result: ${caseItem.hasCavity ? 'Cavity Detected' : 'Healthy/Pending'}',
              ),
              pw.Text('Uploaded: $dateText'),
              pw.SizedBox(height: 16),
              pw.Text(
                'Notes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(caseItem.notes.isNotEmpty ? caseItem.notes : '—'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Manual Review',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                caseItem.reviewNotes.isNotEmpty
                    ? caseItem.reviewNotes
                    : 'Pending',
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'AI Module',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Placeholder: AI module will be integrated later.'),
            ],
          );
        },
      ),
    );

    try {
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'case_report_${caseItem.id}.pdf',
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

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editCase(BuildContext context, Case caseItem) {
    final titleController = TextEditingController(text: caseItem.caseTitle);
    final notesController = TextEditingController(text: caseItem.notes);
    final reviewController = TextEditingController(text: caseItem.reviewNotes);
    String selectedStatus = caseItem.caseStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Case'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Case Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Uploaded', 'Under Review', 'Completed', 'Archived']
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
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Review Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
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
              final success = await caseProvider.updateCase(caseItem.id, {
                'caseTitle': titleController.text,
                'caseStatus': selectedStatus,
                'notes': notesController.text,
                'reviewNotes': reviewController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  AppDialogs.showInfoDialog(context,
                      title: 'Success', message: 'Case updated successfully');
                } else {
                  AppDialogs.showErrorDialog(context,
                      message: 'Failed to update case.');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _archiveCase(BuildContext context, Case caseItem) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Case'),
        content: Text(
          'Are you sure you want to archive "${caseItem.caseTitle.isEmpty ? caseItem.id : caseItem.caseTitle}"?',
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
              backgroundColor: semanticColors?.warning ?? colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _deleteCase(BuildContext context, Case caseItem) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${caseItem.caseTitle.isEmpty ? caseItem.id : caseItem.caseTitle}"?',
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. All images will be deleted.',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
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
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
