import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/scan_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/case_provider.dart';
import '../../widgets/loaders/app_loader.dart';
import '../../core/theme/app_semantic_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadScanDialog extends StatefulWidget {
  const UploadScanDialog({super.key});

  @override
  State<UploadScanDialog> createState() => _UploadScanDialogState();
}

class _UploadScanDialogState extends State<UploadScanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedPatientId;
  String? _imagePath;
  Uint8List? _pickedBytes;
  File? _pickedFile;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a patient'),
          backgroundColor: semantic?.warning ?? colorScheme.secondary,
        ),
      );
      return;
    }

    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );
    final patient = patientProvider.getPatientById(_selectedPatientId!);

    if (patient == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Patient not found'),
            backgroundColor: semantic?.danger ?? colorScheme.error,
          ),
        );
      }
      return;
    }

    // Call upload on the provider
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    try {
      final result = await scanProvider.uploadScan(
        patientId: patient.id,
        patientName: patient.name,
        toothNumber: '',
        notes: _notesController.text.trim(),
        imageFile: kIsWeb ? _pickedBytes : _pickedFile,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Scan uploaded and analyzed successfully!'),
              backgroundColor: semantic?.success ?? colorScheme.primary,
            ),
          );

          // Prompt user to attach to case or create a new case
          await _showAttachOrCreateCaseDialog(
            patient.id,
            result,
            kIsWeb ? _pickedBytes : _pickedFile,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${scanProvider.error}'),
              backgroundColor: semantic?.danger ?? colorScheme.error,
            ),
          );
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading scan: $e'),
            backgroundColor: semantic?.danger ?? colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showAttachOrCreateCaseDialog(
    String patientId,
    Map<String, String> uploadResult,
    dynamic imagePayload,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );
    final patient = patientProvider.getPatientById(patientId);

    final choice = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attach Scan'),
        content: const Text(
          'Would you like to attach this scan to an existing case or create a new case?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'attach'),
            child: const Text('Attach'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'create'),
            child: const Text('Create Case'),
          ),
        ],
      ),
    );

    if (choice == 'create') {
      // Create new case using imagePayload
      try {
        final newCaseId = await caseProvider.createCase(
          patientId: patientId,
          patientName: patient?.name ?? '',
          toothNumber: '',
          imageFiles: [imagePayload],
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newCaseId != null ? 'Case created' : 'Failed to create case',
              ),
              backgroundColor: newCaseId != null
                  ? (semantic?.success ?? colorScheme.primary)
                  : (semantic?.danger ?? colorScheme.error),
            ),
          );
        }
        // If a scan document was created for this upload, link it to the new case
        try {
          final scanId = uploadResult['scanId'];
          if (newCaseId != null && scanId != null && scanId.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('scans')
                .doc(scanId)
                .update({
              'caseId': newCaseId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('Failed to link scan to case: $e');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating case: $e'),
              backgroundColor: semantic?.danger ?? colorScheme.error,
            ),
          );
        }
      }
    } else if (choice == 'attach') {
      // Let user pick an existing case
      final cases = await caseProvider.fetchCasesForPatient(patientId);
      final selected = await showDialog<String?>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Case'),
          children: cases.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No existing cases'),
                  ),
                ]
              : cases
                  .map(
                    (c) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, c.id),
                      child: Text(
                        '${c.toothNumber.isNotEmpty ? '${c.toothNumber} • ' : ''}${c.caseDate.toLocal().toIso8601String().split('T').first}',
                      ),
                    ),
                  )
                  .toList(),
        ),
      );

      if (selected != null) {
        try {
          // Append the uploaded image URL to the selected case
          final imageUrl = uploadResult['imageUrl'];
          if (imageUrl != null) {
            await caseProvider.updateCase(selected, {
              'imageUrls': FieldValue.arrayUnion([imageUrl]),
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Attached to case'),
                  backgroundColor: semantic?.success ?? colorScheme.primary,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to attach to case: $e'),
                backgroundColor: semantic?.danger ?? colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.upload_file,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Upload Dental Scan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<PatientProvider>(
                        builder: (context, patientProvider, child) {
                          return DropdownButtonFormField<String>(
                            value: _selectedPatientId,
                            decoration: const InputDecoration(
                              labelText: 'Select Patient',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: patientProvider.patients
                                .map(
                                  (patient) => DropdownMenuItem(
                                    value: patient.id,
                                    child: Text(patient.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPatientId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a patient';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Image Upload Area
                      InkWell(
                        onTap: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: kIsWeb,
                            );
                            if (result == null) return;

                            final file = result.files.single;
                            setState(() {
                              _imagePath = file.name;
                              if (kIsWeb) {
                                _pickedBytes = file.bytes;
                                _pickedFile = null;
                              } else {
                                if (file.path != null) {
                                  _pickedFile = File(file.path!);
                                }
                                _pickedBytes = null;
                              }
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image selected'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to pick image: $e'),
                                backgroundColor:
                                    semantic?.danger ?? colorScheme.error,
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surfaceContainerLowest,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _imagePath != null
                                      ? Icons.check_circle
                                      : Icons.cloud_upload,
                                  size: 64,
                                  color: _imagePath != null
                                      ? (semantic?.success ??
                                          colorScheme.primary)
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _imagePath != null
                                      ? 'Image selected'
                                      : 'Click to upload dental scan image',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_imagePath != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _imagePath!,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          prefixIcon: Icon(Icons.notes),
                          alignLabelWithHint: true,
                          hintText: 'Any observations or concerns...',
                        ),
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter notes';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
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
                Consumer<ScanProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton.icon(
                      onPressed: provider.loading ? null : _submit,
                      icon: provider.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: AppLoader(size: 16),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(
                        provider.loading ? 'Analyzing...' : 'Upload & Analyze',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
