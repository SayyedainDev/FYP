import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/patient.dart';
import '../../providers/patient_provider.dart';
import 'add_patient_dialog.dart';

class PatientSelectionDialog extends StatefulWidget {
  const PatientSelectionDialog({super.key});

  @override
  State<PatientSelectionDialog> createState() => _PatientSelectionDialogState();
}

class _PatientSelectionDialogState extends State<PatientSelectionDialog> {
  String? _selectedPatientId;
  bool _isNewPatient = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
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
            // Professional Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
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
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_search,
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
                          'Select Patient',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a patient for this scan',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle buttons
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ToggleButton(
                              label: 'Existing Patient',
                              isSelected: !_isNewPatient,
                              onPressed: () =>
                                  setState(() => _isNewPatient = false),
                              icon: Icons.person,
                            ),
                          ),
                          Expanded(
                            child: _ToggleButton(
                              label: 'New Patient',
                              isSelected: _isNewPatient,
                              onPressed: () =>
                                  setState(() => _isNewPatient = true),
                              icon: Icons.person_add,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Content based on selection
                    if (!_isNewPatient)
                      _ExistingPatientSelector(
                        onPatientSelected: (patientId) {
                          setState(() => _selectedPatientId = patientId);
                        },
                        selectedPatientId: _selectedPatientId,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add_alt,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Create New Patient',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A new patient record will be created from the details you provide',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action buttons
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
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isNewPatient
                        ? () => _createNewPatient(context)
                        : (_selectedPatientId != null
                            ? () => Navigator.pop(context, _selectedPatientId)
                            : null),
                    icon: Icon(
                      _isNewPatient ? Icons.add : Icons.check,
                      size: 18,
                    ),
                    label: Text(_isNewPatient ? 'Create Patient' : 'Continue'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewPatient(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddPatientDialog(
        onPatientCreated: (patientId) {
          Navigator.pop(ctx);
          Navigator.pop(context, patientId);
        },
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final IconData icon;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExistingPatientSelector extends StatelessWidget {
  final Function(String) onPatientSelected;
  final String? selectedPatientId;

  const _ExistingPatientSelector({
    required this.onPatientSelected,
    required this.selectedPatientId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, child) {
        final patients = patientProvider.patients;

        if (patients.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline,
                    size: 40, color: colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'No Patients Found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please create a patient first',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ...patients.map(
                (patient) => _PatientOption(
                  patient: patient,
                  isSelected: selectedPatientId == patient.id,
                  onSelected: () => onPatientSelected(patient.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PatientOption extends StatelessWidget {
  final Patient patient;
  final bool isSelected;
  final VoidCallback onSelected;

  const _PatientOption({
    required this.patient,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
              left: isSelected
                  ? BorderSide(color: colorScheme.primary, width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onSelected(),
                activeColor: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${patient.age}y',
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
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            patient.gender,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
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
      ),
    );
  }
}
