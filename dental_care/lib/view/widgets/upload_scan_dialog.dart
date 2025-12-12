import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/patient_provider.dart';

class UploadScanDialog extends StatefulWidget {
  const UploadScanDialog({super.key});

  @override
  State<UploadScanDialog> createState() => _UploadScanDialogState();
}

class _UploadScanDialogState extends State<UploadScanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _toothNumberController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedPatientId;
  String? _imagePath;

  @override
  void dispose() {
    _toothNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: Colors.orange,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient not found'),
          backgroundColor: Colors.red,
        ),
      );
      try {
        // The ScanProvider currently doesn't expose an `addScan` method.
        // Simulate upload and analysis here or replace this with the correct
        // provider method (e.g. `uploadScan` or similar) if available.
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan uploaded and analyzed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        Navigator.pop(context);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.upload_file,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Upload Dental Scan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
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
                      TextFormField(
                        controller: _toothNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Tooth Number',
                          prefixIcon: Icon(Icons.medical_services),
                          hintText: 'e.g., 11, 14, 36',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter tooth number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Image Upload Area
                      InkWell(
                        onTap: () {
                          // Simulate image picker
                          setState(() {
                            _imagePath =
                                'dental_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image selected (simulated)'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
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
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _imagePath != null
                                      ? 'Image selected'
                                      : 'Click to upload dental scan image',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_imagePath != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _imagePath!,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(
                        provider.loading ? 'Analyzing...' : 'Upload & Analyze',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
