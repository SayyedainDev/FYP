import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';

import '../models/patient.dart';
import '../models/scan.dart';
import '../models/case.dart';
import '../providers/patient_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/case_provider.dart';
import '../providers/prescription_provider.dart';
import '../provider/auth_provider.dart';
import '../core/animation_constants.dart';
import '../core/theme/app_semantic_colors.dart';
import '../utils/app_dialogs.dart';
import '../utils/global_error_handler.dart';
import 'widgets/add_patient_dialog.dart';
import 'widgets/edit_patient_dialog.dart';
import '../widgets/loaders/app_loader.dart';
import 'widgets/create_case_dialog.dart';
import 'widgets/write_prescription_dialog.dart';
import 'widgets/prescription_list_view.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  Key _prescriptionListKey = UniqueKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  void _loadPatients() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );

    // Get current user ID - prioritize Firebase Auth current user
    String? uid = authProvider.currentUserId;

    // Fallback to authProvider.uid if needed
    uid ??= authProvider.uid;

    debugPrint('Loading patients for UID: $uid');

    if (uid != null) {
      try {
        await patientProvider
            .fetchPatients(uid)
            .timeout(const Duration(seconds: 30));
        patientProvider.listenToPatients(uid);
      } on TimeoutException catch (_) {
        if (mounted) {
          AppDialogs.showErrorDialog(context,
              message: "The request timed out. Check your connection.");
        }
      } on SocketException catch (_) {
        if (mounted) AppDialogs.showNoInternetDialog(context);
      } catch (e, stack) {
        if (mounted) GlobalErrorHandler.instance.handleError(e, stack);
      }
    } else {
      debugPrint('No UID found - user may not be logged in');
    }
  }

  // Prominent card decoration matching your specification
  BoxDecoration get _prominentCardDecoration {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.outlineVariant, width: 1),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Patients',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPatientDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Patient'),
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
                    const SizedBox(width: 12),
                    // Prescription quick-action button
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Open a simple patient selector then the write prescription dialog
                        final selected = await showDialog<Patient?>(
                          context: context,
                          builder: (ctx) {
                            final patients =
                                Provider.of<PatientProvider>(context).patients;
                            return Dialog(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 600),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'Select Patient for Prescription',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 300,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: patients.length,
                                        itemBuilder: (_, i) {
                                          final p = patients[i];
                                          return ListTile(
                                            title: Text(p.name),
                                            subtitle: Text(p.contactPhone),
                                            onTap: () =>
                                                Navigator.of(ctx).pop(p),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(null),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        if (selected != null) {
                          // find latest case for this patient
                          final caseProv =
                              Provider.of<CaseProvider>(context, listen: false);
                          final cases = caseProv.allCases
                              .where((c) => c.patientId == selected.id)
                              .toList();
                          Case caseData;
                          if (cases.isNotEmpty) {
                            caseData = cases.first;
                          } else {
                            caseData = Case(
                              id: '',
                              patientId: selected.id,
                              patientName: selected.name,
                              toothNumber: '',
                              caseDate: DateTime.now(),
                              imageUrls: const [],
                              analysisResults: const {
                                'status': 'Pending AI Analysis'
                              },
                              notes: '',
                            );
                          }

                          final authProv =
                              Provider.of<AuthProvider>(context, listen: false);
                          final prescriptionProvider =
                              Provider.of<PrescriptionProvider>(context,
                                  listen: false);
                          showDialog<bool>(
                            context: context,
                            builder: (_) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider<
                                        PrescriptionProvider>.value(
                                    value: prescriptionProvider),
                                ChangeNotifierProvider.value(value: authProv),
                              ],
                              child: WritePrescriptionDialog(
                                  patient: selected, caseId: caseData.id),
                            ),
                          ).then((created) {
                            if (created == true) {
                              // optionally refresh patients or show snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Prescription created')));
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('Write Prescription'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
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
                const SizedBox(height: 32),

                // Patient List with StreamBuilder for real-time updates
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final uid = authProvider.currentUserId ?? authProvider.uid;

                    if (uid == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(64.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'User not authenticated',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('patients')
                          .where('dentistUid', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(64.0),
                              child: AppLoader(message: 'Loading patients...'),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(64.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading patients: ${snapshot.error}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final patients = (snapshot.data?.docs
                                .map((doc) => Patient.fromFirestore(doc))
                                .toList() ??
                            [])
                          ..sort(
                            (a, b) => b.createdAt.compareTo(a.createdAt),
                          );

                        if (patients.isEmpty) {
                          return Container(
                            decoration: _prominentCardDecoration,
                            padding: const EdgeInsets.all(64.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No patients found',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Add New Patient" to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Responsive grid: adjust columns and aspect ratio by width
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            int crossAxisCount = 3;
                            double childAspect = 1.2;

                            if (width < 600) {
                              crossAxisCount = 1;
                              childAspect = 2.4;
                            } else if (width < 900) {
                              crossAxisCount = 2;
                              childAspect = 1.8;
                            } else if (width < 1200) {
                              crossAxisCount = 3;
                              childAspect = 1.3;
                            } else {
                              crossAxisCount = 4;
                              childAspect = 1.2;
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: childAspect,
                              ),
                              itemCount: patients.length,
                              itemBuilder: (context, index) {
                                final patient = patients[index];
                                return _PatientCard(
                                  patient: patient,
                                  decoration: _prominentCardDecoration,
                                  onTap: () =>
                                      _showPatientDetails(context, patient),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPatientDialog(),
    );
  }

  Future<void> _showEditPatientDialog(
    BuildContext context,
    Patient patient,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUserId ?? authProvider.uid;
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.5),
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: patientProvider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: EditPatientDialog(patient: patient),
      ),
    );

    if (!mounted) return;

    if (result == true && uid != null) {
      // Refresh patient list after successful edit
      final patientProvider = Provider.of<PatientProvider>(
        this.context,
        listen: false,
      );
      await patientProvider.fetchPatients(uid);
    }
  }

  Future<void> _confirmDeletePatient(
    BuildContext context,
    Patient patient,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUserId ?? authProvider.uid;
    if (uid == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Delete ${patient.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await Provider.of<PatientProvider>(context, listen: false)
          .deletePatient(patient.id, uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete patient: $e')),
        );
      }
    }
  }

  void _showPatientDetails(BuildContext context, Patient patient) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final success = semantic?.success ?? colorScheme.primary;
    showDialog(
      context: context,
      barrierColor: colorScheme.shadow.withValues(alpha: 0.5),
      builder: (dialogContext) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ScanProvider>.value(
            value: Provider.of<ScanProvider>(context, listen: false),
          ),
          ChangeNotifierProvider<PrescriptionProvider>.value(
            value: Provider.of<PrescriptionProvider>(context, listen: false),
          ),
        ],
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 650,
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
              children: [
                // Professional Header with gradient
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
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.onPrimary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            patient.initials,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.onPrimary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.onPrimary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${patient.age} years',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.onPrimary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.onPrimary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    patient.gender,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Personal Information Section
                          const _SectionHeader('Personal Information'),
                          const SizedBox(height: 12),
                          _DetailBox(
                            icon: Icons.calendar_today,
                            label: 'Date of Birth',
                            value:
                                '${patient.dob.day.toString().padLeft(2, '0')}/${patient.dob.month.toString().padLeft(2, '0')}/${patient.dob.year}',
                          ),
                          const SizedBox(height: 12),

                          // Contact Information
                          Row(
                            children: [
                              if (patient.contactPhone.isNotEmpty)
                                Expanded(
                                  child: _DetailBox(
                                    icon: Icons.phone,
                                    label: 'Phone',
                                    value: patient.contactPhone,
                                  ),
                                ),
                              if (patient.contactPhone.isNotEmpty &&
                                  patient.contactEmail.isNotEmpty)
                                const SizedBox(width: 12),
                              if (patient.contactEmail.isNotEmpty)
                                Expanded(
                                  child: _DetailBox(
                                    icon: Icons.email,
                                    label: 'Email',
                                    value: patient.contactEmail,
                                  ),
                                ),
                            ],
                          ),

                          // Notes Section
                          if (patient.notes.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const _SectionHeader('Medical Notes'),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                patient.notes,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],

                          // Prescriptions Section
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionHeader('Prescriptions'),
                              TextButton.icon(
                                onPressed: () {
                                  // Prescriptions are already fully displayed below
                                  // So just scroll to show them
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Scroll down to see all prescriptions'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PrescriptionListView(
                            key: _prescriptionListKey,
                            patientId: patient.id,
                            patientName: patient.name,
                            patientPhone: patient.contactPhone,
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionHeader('Recent Scans'),
                              TextButton.icon(
                                onPressed: () async {
                                  final scans = await Provider.of<ScanProvider>(
                                    dialogContext,
                                    listen: false,
                                  ).fetchScansForPatient(patient.id);

                                  if (!context.mounted) return;

                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Recent Scans'),
                                      content: SizedBox(
                                        width: 700,
                                        child: scans.isEmpty
                                            ? const Text(
                                                'No scans found for this patient.',
                                              )
                                            : ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: scans.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 12),
                                                itemBuilder: (_, index) {
                                                  final scan = scans[index];
                                                  return ListTile(
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 0,
                                                      vertical: 0,
                                                    ),
                                                    leading: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                      child: Image.network(
                                                        scan.imageUrl,
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                Container(
                                                          width: 56,
                                                          height: 56,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Icon(
                                                            Icons.image,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    title:
                                                        Text(scan.cavityStatus),
                                                    subtitle: Text(
                                                      '${scan.scanDate.toLocal().toString().split('.').first} • ${scan.timeAgo}',
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            context,
                                          ),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<List<Scan>>(
                            future: Provider.of<ScanProvider>(
                              dialogContext,
                              listen: false,
                            ).fetchScansForPatient(patient.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final scans = snapshot.data ?? [];
                              if (scans.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    'No scans found for this patient.',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }

                              final recentScans = scans.take(3).toList();
                              return Column(
                                children: recentScans.map((scan) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              scan.imageUrl,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  scan.cavityStatus,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  scan.timeAgo,
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            scan.hasCavity
                                                ? 'Cavity'
                                                : 'Healthy',
                                            style: TextStyle(
                                              color: scan.hasCavity
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          // Metadata
                          const SizedBox(height: 20),
                          Divider(color: colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Record Created',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${patient.createdAt.day.toString().padLeft(2, '0')}/${patient.createdAt.month.toString().padLeft(2, '0')}/${patient.createdAt.year}',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                      top: BorderSide(
                          color: colorScheme.outlineVariant, width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            // Open create case dialog with this patient preselected
                            final patientProv = Provider.of<PatientProvider>(
                                context,
                                listen: false);
                            final caseProv = Provider.of<CaseProvider>(context,
                                listen: false);
                            final authProv = Provider.of<AuthProvider>(context,
                                listen: false);

                            await showDialog(
                              context: context,
                              builder: (context) => MultiProvider(
                                providers: [
                                  ChangeNotifierProvider.value(
                                      value: patientProv),
                                  ChangeNotifierProvider.value(value: caseProv),
                                  ChangeNotifierProvider.value(value: authProv),
                                ],
                                child: CreateCaseDialog(
                                    initialPatientId: patient.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_box, size: 18),
                          label: const Text('New Case'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: success,
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
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Get the latest case for this patient to link prescription
                            final caseProvider = Provider.of<CaseProvider>(
                                context,
                                listen: false);
                            final patientCases = caseProvider.cases
                                .where((c) => c.patientId == patient.id)
                                .toList();

                            // Use the most recent case or create a minimal one
                            Case caseData = Case(
                              id: '',
                              patientId: patient.id,
                              patientName: patient.name,
                              toothNumber: '',
                              caseDate: DateTime.now(),
                              imageUrls: const [],
                              analysisResults: const {'status': 'Pending'},
                              notes: '',
                            );

                            if (patientCases.isNotEmpty) {
                              caseData = patientCases.last;
                            }

                            // Use the case (either existing or minimal)
                            final latestCase = caseData;

                            if (mounted) {
                              Navigator.pop(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final prescriptionProvider =
                                  Provider.of<PrescriptionProvider>(context,
                                      listen: false);
                              final authProv = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);
                              final created = await showDialog<bool>(
                                context: context,
                                builder: (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider<
                                            PrescriptionProvider>.value(
                                        value: prescriptionProvider),
                                    ChangeNotifierProvider.value(
                                        value: authProv),
                                  ],
                                  child: WritePrescriptionDialog(
                                    patient: patient,
                                    caseId: latestCase.id,
                                  ),
                                ),
                              );

                              if (created == true && mounted) {
                                // Recreate the prescription list to force reload
                                setState(() {
                                  _prescriptionListKey = UniqueKey();
                                });
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Prescription created')));
                              }
                            }
                          },
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text('Write Prescription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
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
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _showEditPatientDialog(context, patient);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Patient'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _confirmDeletePatient(context, patient);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete Patient'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _DetailBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  final Patient patient;
  final BoxDecoration decoration;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.decoration,
    required this.onTap,
  });

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.smooth,
          transform: Matrix4.identity()..translate(0, _isHovered ? -8 : 0, 0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient avatar and name
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.patient.initials,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patient.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${widget.patient.age}y',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          widget.patient.gender == 'Female'
                                              ? Icons.female
                                              : Icons.male,
                                          size: 12,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.patient.gender,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
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
                      ],
                    ),
                    const Spacer(),

                    // Contact info
                    if (widget.patient.contactPhone.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.patient.contactPhone,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (widget.patient.contactEmail.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.patient.contactEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // View details indicator
                    if (_isHovered) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
