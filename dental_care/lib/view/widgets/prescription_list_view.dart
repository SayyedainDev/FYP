import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/prescription.dart';
import '../../providers/prescription_provider.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../utils/app_dialogs.dart';
import '../../widgets/loaders/app_loader.dart';

class PrescriptionListView extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientPhone;

  const PrescriptionListView({
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    super.key,
  });

  @override
  State<PrescriptionListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<PrescriptionListView> {
  late Future<List<Prescription>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize with empty list to avoid LateInitializationError
    _prescriptionsFuture = Future.value([]);

    // Defer provider access until after the first frame so the surrounding
    // widget tree (which may include dialogs or routes) has mounted the
    // providers. This avoids ProviderNotFoundError when this widget is
    // instantiated from contexts that are ancestors of the providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPrescriptions();
    });
  }

  void _loadPrescriptions() {
    try {
      final provider =
          Provider.of<PrescriptionProvider>(context, listen: false);
      _prescriptionsFuture =
          provider.fetchPatientPrescriptions(widget.patientId);
    } catch (e) {
      // In case provider is still not available, return an empty list to
      // avoid crashing the UI. Caller can refresh once provider becomes
      // available.
      _prescriptionsFuture = Future.value(<Prescription>[]);
    }
  }

  Future<void> _shareViaWhatsApp(Prescription prescription) async {
    try {
      final message = prescription.toWhatsAppMessage();
      final phoneNumber =
          prescription.patientPhone.replaceAll(RegExp(r'\D'), '');

      // Add country code if not present
      String whatsappPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        whatsappPhone = '+92$phoneNumber'; // Default to +92 for Pakistan
      }

      final whatsappUrl =
          'https://wa.me/$whatsappPhone?text=${Uri.encodeComponent(message)}';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));

        // Mark as shared in provider
        final prescriptionProvider =
            Provider.of<PrescriptionProvider>(context, listen: false);
        await prescriptionProvider.markAsShared(prescription.id);

        if (mounted) {
          setState(() {
            _loadPrescriptions();
          });
        }
      } else {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message:
                'Unable to open WhatsApp. Please ensure WhatsApp is installed.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Error sharing prescription: $e',
        );
      }
    }
  }

  Future<void> _deletePrescription(Prescription prescription) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context,
      title: 'Delete Prescription',
      message: 'Are you sure you want to delete this prescription?',
    );

    if (confirmed == true) {
      final provider =
          Provider.of<PrescriptionProvider>(context, listen: false);
      final success = await provider.deletePrescription(prescription.id);

      if (mounted) {
        if (success) {
          AppDialogs.showSuccessDialog(
            context,
            message: 'Prescription deleted successfully',
          );
          setState(() {
            _loadPrescriptions();
          });
        } else {
          AppDialogs.showErrorDialog(
            context,
            message: 'Failed to delete prescription',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Prescription>>(
      future: _prescriptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child:
                Center(child: AppLoader(message: 'Loading prescriptions...')),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading prescriptions: ${snapshot.error}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final prescriptions = snapshot.data ?? [];

        if (prescriptions.isEmpty) {
          // Compact empty state to avoid large blank panels inside the
          // patient profile layout. Keeps UI tidy and lets surrounding
          // content flow naturally.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.description_outlined,
                    color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'No prescriptions yet',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prescriptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final prescription = prescriptions[index];
            return _PrescriptionCard(
              prescription: prescription,
              onShare: () => _shareViaWhatsApp(prescription),
              onDelete: () => _deletePrescription(prescription),
            );
          },
        );
      },
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _PrescriptionCard({
    required this.prescription,
    required this.onShare,
    required this.onDelete,
  });

  static void _showPrescriptionPopup(
      BuildContext context, Prescription prescription) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${prescription.createdAt.toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.2),
                              child: Icon(Icons.person,
                                  color: colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prescription.patientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    prescription.patientPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Diagnosis
                      if (prescription.diagnosis.isNotEmpty) ...[
                        Text(
                          'Diagnosis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prescription.diagnosis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Prescription Details
                      if (prescription.prescription.isNotEmpty) ...[
                        Text(
                          'Medications & Treatment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            prescription.prescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Follow-up
                      if (prescription.followUpTreatment.isNotEmpty) ...[
                        Text(
                          'Follow-up Treatment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prescription.followUpTreatment,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Precautions
                      if (prescription.precautions.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    colorScheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_rounded,
                                  color: colorScheme.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Precautions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      prescription.precautions,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onErrorContainer,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final success = semantic?.success ?? colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescription',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${prescription.createdAt.toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: prescription.isShared
                        ? success.withValues(alpha: 0.16)
                        : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: prescription.isShared
                          ? success.withValues(alpha: 0.35)
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        prescription.isShared
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 14,
                        color: prescription.isShared
                            ? success
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        prescription.isShared ? 'Shared' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: prescription.isShared
                              ? success
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Diagnosis Section
            if (prescription.diagnosis.isNotEmpty) ...[
              Text(
                'Diagnosis',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prescription.diagnosis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Prescription Section
            if (prescription.prescription.isNotEmpty) ...[
              Text(
                'Prescription',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  prescription.prescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                    height: 1.4,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Follow-up Section
            if (prescription.followUpTreatment.isNotEmpty) ...[
              Text(
                'Follow-up Treatment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prescription.followUpTreatment,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Precautions Section
            if (prescription.precautions.isNotEmpty) ...[
              Text(
                'Precautions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prescription.precautions,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showPrescriptionPopup(context, prescription),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
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
