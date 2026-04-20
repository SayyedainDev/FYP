import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/patient.dart';
import '../../models/case.dart';
import '../../models/prescription.dart';
import '../../provider/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/app_dialogs.dart';
import '../../service/diagnosis_suggestion_service.dart';

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
  List<SuggestionItem> _diagnosisSuggestions = [];
  bool _loadingSuggestions = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _diagnosisController = TextEditingController();
    _diagnosisController.addListener(_onDiagnosisChanged);
    _prescriptionController = TextEditingController();
    _followUpController = TextEditingController();
    _precautionsController = TextEditingController();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _diagnosisController.removeListener(_onDiagnosisChanged);
    _prescriptionController.dispose();
    _followUpController.dispose();
    _precautionsController.dispose();
    super.dispose();
  }

  Future<void> _shareOnWhatsApp(Prescription prescription) async {
    try {
      final message = prescription.toWhatsAppMessage();
      final encodedMessage = Uri.encodeComponent(message);
      final phone = prescription.patientPhone.replaceAll(RegExp(r'\D'), '');

      if (phone.isEmpty) {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message:
                'Patient phone number not found. Cannot share on WhatsApp.',
          );
        }
        return;
      }

      final whatsappUrl = 'https://wa.me/$phone?text=$encodedMessage';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );

        // Mark as shared
        if (mounted) {
          final prescriptionProvider =
              Provider.of<PrescriptionProvider>(context, listen: false);
          await prescriptionProvider.markAsShared(prescription.id);

          AppDialogs.showSuccessDialog(
            context,
            message: 'Prescription shared on WhatsApp!',
          ).then((_) {
            if (mounted) Navigator.pop(context, true);
          });
        }
      } else {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message:
                'WhatsApp is not installed. Please install WhatsApp to share.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Error sharing on WhatsApp: $e',
        );
      }
    }
  }

  void _showWhatsAppShareDialog(Prescription prescription) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Share on WhatsApp?'),
        content: Text(
          'Do you want to send this prescription to ${prescription.patientName} via WhatsApp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              _shareOnWhatsApp(prescription);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Share on WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? '';
    final dentistName = userEmail.split('@')[0];

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
        // Close the dialog and signal success to the caller so parent
        // can refresh lists. Sharing can be done from the prescriptions
        // list view if needed.
        if (mounted) Navigator.pop(context, true);
      } else {
        // Show error from provider
        final errorMsg = prescriptionProvider.errorMessage ??
            'Failed to save prescription. Please try again.';
        AppDialogs.showErrorDialog(
          context,
          message: errorMsg,
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

  void _onDiagnosisChanged() async {
    final q = _diagnosisController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _diagnosisSuggestions = [];
      });
      return;
    }
    setState(() => _loadingSuggestions = true);
    final svc = DiagnosisSuggestionService.instance;
    final results = await svc.search(q);
    if (!mounted) return;
    setState(() {
      _diagnosisSuggestions = results;
      _loadingSuggestions = false;
    });
  }

  Widget _buildFieldLabel(String label, ColorScheme colorScheme,
      {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(color: colorScheme.error, fontSize: 14),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration(
      String hintText, ColorScheme colorScheme) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 48,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
              padding: const EdgeInsets.all(24),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For ${widget.patient.name}',
                          style: TextStyle(
                            color:
                                colorScheme.onPrimary.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSmallScreen)
                    Tooltip(
                      message: 'Fill all required fields and save',
                      child: Icon(
                        Icons.info_outline,
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Diagnosis
                        _buildFieldLabel('Diagnosis', colorScheme,
                            isRequired: true),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _diagnosisController,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _buildInputDecoration(
                                'Enter diagnosis details...',
                                colorScheme,
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Diagnosis is required';
                                }
                                if (value!.length < 3) {
                                  return 'Diagnosis must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_loadingSuggestions)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Loading suggestions...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_diagnosisSuggestions.isNotEmpty)
                              Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 220),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _diagnosisSuggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                  itemBuilder: (ctx, i) {
                                    final it = _diagnosisSuggestions[i];
                                    final treatments = it.treatments;
                                    final meds = it.medications;
                                    return Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  it.diagnosis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 32,
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _diagnosisController
                                                          .text = it.diagnosis;
                                                      _diagnosisSuggestions =
                                                          [];
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: colorScheme.primary,
                                                  ),
                                                  label: const Text(
                                                    'Use',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (treatments.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Treatments:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children:
                                                  treatments.map<Widget>((t) {
                                                return SizedBox(
                                                  height: 28,
                                                  child: ActionChip(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    label: Text(
                                                      t.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      final curr =
                                                          _prescriptionController
                                                              .text
                                                              .trim();
                                                      final addition =
                                                          t.toString();
                                                      _prescriptionController
                                                          .text = curr
                                                              .isEmpty
                                                          ? addition
                                                          : '$curr\n$addition';
                                                    },
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                          if (meds.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Medications:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: meds.map<Widget>((m) {
                                                final medText =
                                                    '${m['name']} ${m['dose']} ${m['freq']}';
                                                return SizedBox(
                                                  height: 28,
                                                  child: ActionChip(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    label: Text(
                                                      medText,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      final curr =
                                                          _prescriptionController
                                                              .text
                                                              .trim();
                                                      _prescriptionController
                                                          .text = curr
                                                              .isEmpty
                                                          ? medText
                                                          : '$curr\n$medText';
                                                    },
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        // Prescription
                        _buildFieldLabel('Prescription', colorScheme,
                            isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _prescriptionController,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _buildInputDecoration(
                            'Enter medications, dosage, and frequency...',
                            colorScheme,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Prescription is required';
                            }
                            if (value!.length < 5) {
                              return 'Please provide detailed prescription';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        // Follow-up Treatment
                        _buildFieldLabel('Follow-up Treatment', colorScheme,
                            isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _followUpController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _buildInputDecoration(
                            'Enter follow-up appointments and treatment plans...',
                            colorScheme,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Follow-up treatment is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        // Precautions
                        _buildFieldLabel('Precautions', colorScheme,
                            isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _precautionsController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _buildInputDecoration(
                            'Enter precautions and care instructions...',
                            colorScheme,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Precautions are required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
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
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Save Prescription',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
