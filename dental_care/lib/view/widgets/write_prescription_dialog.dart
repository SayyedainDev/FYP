import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/patient.dart';
import '../../models/case.dart';
import '../../provider/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/app_dialogs.dart';
// removed unused imports

class WritePrescriptionDialog extends StatefulWidget {
  final Patient patient;
  final Case caseData;

  const WritePrescriptionDialog({
    required this.patient,
    required this.caseData,
    super.key,
  });

  @override
  State<WritePrescriptionDialog> createState() =>
      _WritePrescriptionDialogState();
}

class _WritePrescriptionDialogState extends State<WritePrescriptionDialog> {
  late final TextEditingController _diagnosisController;
  late final TextEditingController _prescriptionController;
  late final TextEditingController _followUpController;
  late final TextEditingController _precautionsController;

  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _diagnosisController = TextEditingController();
    _prescriptionController = TextEditingController();
    _followUpController = TextEditingController();
    _precautionsController = TextEditingController();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _followUpController.dispose();
    _precautionsController.dispose();
    super.dispose();
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? '';
    final dentistName =
        userEmail.split('@')[0]; // Use first part of email as name

    try {
      setState(() => _isSubmitting = true);

      final result = await prescriptionProvider.createPrescription(
        dentistUid: authProvider.currentUserId ?? authProvider.uid ?? '',
        dentistName: dentistName,
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        patientPhone: widget.patient.contactPhone,
        caseId: widget.caseData.id,
        diagnosis: _diagnosisController.text.trim(),
        prescription: _prescriptionController.text.trim(),
        followUpTreatment: _followUpController.text.trim(),
        precautions: _precautionsController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (result != null) {
        AppDialogs.showSuccessDialog(
          context,
          message: 'Prescription saved successfully!',
        ).then((_) {
          Navigator.pop(context, true);
        });
      } else {
        AppDialogs.showErrorDialog(
          context,
          message: 'Failed to save prescription. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppDialogs.showErrorDialog(
        context,
        message: 'Error saving prescription: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Write Prescription',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'For ${widget.patient.name}',
                              style: TextStyle(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Form Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diagnosis Field
                      Text(
                        'Diagnosis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _diagnosisController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter diagnosis details...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Diagnosis is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Prescription Field
                      Text(
                        'Prescription',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _prescriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Enter medications, dosage, and frequency...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Prescription is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Follow-up Treatment Field
                      Text(
                        'Follow-up Treatment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _followUpController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Enter follow-up appointments and treatment plans...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Follow-up treatment is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Precautions Field
                      Text(
                        'Precautions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _precautionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Enter precautions and care instructions...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Precautions are required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _isSubmitting
                            ? colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5)
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _savePrescription,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label:
                        Text(_isSubmitting ? 'Saving...' : 'Save Prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
