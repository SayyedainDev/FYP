import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/case_provider.dart';
import '../../providers/patient_provider.dart';
import '../../provider/auth_provider.dart';

class CreateCaseDialog extends StatefulWidget {
  final String? initialPatientId;
  const CreateCaseDialog({super.key, this.initialPatientId});

  @override
  State<CreateCaseDialog> createState() => _CreateCaseDialogState();
}

class _CreateCaseDialogState extends State<CreateCaseDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  final _notesController = TextEditingController();
  final _toothNumberController = TextEditingController();
  String? _selectedStatus = 'Uploaded';

  List<PlatformFile>? _pickedFiles;
  List<Uint8List>? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _toothNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result == null) return;
      setState(() {
        _pickedFiles = result.files;
        if (kIsWeb) {
          _pickedBytes = result.files.map((f) => f.bytes!).toList();
        } else {
          _pickedBytes = null;
        }
      });
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final colorScheme = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a patient'),
          backgroundColor: colorScheme.secondary,
        ),
      );
      return;
    }
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUserId == null && auth.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be signed in to create a case'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }
    try {
      List<dynamic> payload = [];
      if (kIsWeb) {
        // use bytes
        if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
          payload = List<dynamic>.from(_pickedBytes!);
        }
      } else {
        if (_pickedFiles != null && _pickedFiles!.isNotEmpty) {
          // Ensure paths are present
          final missing = _pickedFiles!.where((f) => f.path == null).toList();
          if (missing.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Selected files are not accessible'),
                backgroundColor: colorScheme.error,
              ),
            );
            return;
          }
          payload = _pickedFiles!.map((f) => File(f.path!)).toList();
        }
      }

      final caseId = await caseProvider.createCase(
        patientId: _selectedPatientId!,
        patientName: Provider.of<PatientProvider>(
              context,
              listen: false,
            ).getPatientById(_selectedPatientId!)?.name ??
            '',
        toothNumber: _toothNumberController.text.trim(),
        imageFiles: payload,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (caseId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Case created successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        } else {
          final msg = caseProvider.error ?? 'Unknown error creating case';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create case: $msg'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating case: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);
    final patients = patientProvider.patients;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Case',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add clinical images and notes to create a new patient case',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Dropdown
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedPatientId,
                      decoration: const InputDecoration(labelText: 'Patient'),
                      items: patients
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPatientId = v),
                      validator: (v) =>
                          v == null ? 'Please select a patient' : null,
                    ),
                    const SizedBox(height: 16),

                    // Tooth Number and Status Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _toothNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Tooth Number (optional)',
                              hintText: 'e.g., 16, Molar',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(
                                labelText: 'Initial Status'),
                            items: <String>[
                              'Uploaded',
                              'Under Review',
                              'Completed',
                            ]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedStatus = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Image picker + preview
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Images'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pickedFiles != null &&
                                  _pickedFiles!.isNotEmpty
                              ? SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (c, i) {
                                      final f = _pickedFiles![i];
                                      if (kIsWeb && f.bytes != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.memory(
                                            f.bytes!,
                                            width: 96,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      if (f.path != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            File(f.path!),
                                            width: 96,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return Container(
                                        width: 96,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerLowest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemCount: _pickedFiles!.length,
                                  ),
                                )
                              : Text(
                                  'No images selected',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_selectedPatientId == null ||
                            (_pickedFiles == null || _pickedFiles!.isEmpty))
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Create Case',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
