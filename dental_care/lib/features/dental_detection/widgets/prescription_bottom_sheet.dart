import 'package:flutter/material.dart';
import '../../../data/models/detection_record.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/repositories/detection_repository.dart';

class PrescriptionBottomSheet extends StatefulWidget {
  final DetectionRecord record;
  final String patientName;
  final Function(PrescriptionModel) onSaved;

  const PrescriptionBottomSheet({
    super.key,
    required this.record,
    required this.patientName,
    required this.onSaved,
  });

  @override
  State<PrescriptionBottomSheet> createState() => _PrescriptionBottomSheetState();
}

class _PrescriptionBottomSheetState extends State<PrescriptionBottomSheet> {
  late final TextEditingController _diagnosisController;
  final _instructionsController = TextEditingController();
  DateTime? _followUpDate;
  final List<MedicationItem> _medications = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final defaultDiagnosis = widget.record.conditionsFound.isNotEmpty 
        ? widget.record.conditionsFound.join(', ')
        : 'General checkup';
    _diagnosisController = TextEditingController(text: defaultDiagnosis);
    
    // Add one empty medication by default
    _addMedication();
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationItem(name: '', dose: '', frequency: '', duration: ''));
    });
  }

  void _removeMedication(int index) {
    if (_medications.length > 1) {
      setState(() {
        _medications.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a diagnosis')),
      );
      return;
    }

    setState(() => _saving = true);
    
    try {
      final repo = DetectionRepository();
      
      // Filter out empty medications
      final validMedications = _medications.where((m) => m.name.trim().isNotEmpty).toList();
      
      final prescription = await repo.savePrescription(
        patientId: widget.record.patientId,
        detectionId: widget.record.id,
        diagnosis: _diagnosisController.text.trim(),
        medications: validMedications,
        instructions: _instructionsController.text.trim(),
        followUpDate: _followUpDate,
      );
      
      widget.onSaved(prescription);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prescription: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _followUpDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 0)],
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Write Prescription',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Patient: ${widget.patientName}',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.record.conditionsFound.isNotEmpty) ...[
                    Text('Detected Conditions', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.record.conditionsFound.map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        backgroundColor: theme.colorScheme.errorContainer,
                        labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  TextField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Medications', style: theme.textTheme.titleMedium),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        onPressed: _addMedication,
                      ),
                    ],
                  ),
                  
                  ...List.generate(_medications.length, (index) {
                    final med = _medications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: theme.dividerColor)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: med.name,
                                    decoration: const InputDecoration(labelText: 'Medication Name', isDense: true),
                                    onChanged: (v) => _medications[index] = MedicationItem(name: v, dose: _medications[index].dose, frequency: _medications[index].frequency, duration: _medications[index].duration),
                                  ),
                                ),
                                if (_medications.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _removeMedication(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: med.dose,
                                    decoration: const InputDecoration(labelText: 'Dose', isDense: true),
                                    onChanged: (v) => _medications[index] = MedicationItem(name: _medications[index].name, dose: v, frequency: _medications[index].frequency, duration: _medications[index].duration),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: med.frequency,
                                    decoration: const InputDecoration(labelText: 'Frequency', isDense: true),
                                    onChanged: (v) => _medications[index] = MedicationItem(name: _medications[index].name, dose: _medications[index].dose, frequency: v, duration: _medications[index].duration),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: med.duration,
                                    decoration: const InputDecoration(labelText: 'Duration', isDense: true),
                                    onChanged: (v) => _medications[index] = MedicationItem(name: _medications[index].name, dose: _medications[index].dose, frequency: _medications[index].frequency, duration: v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Follow-up Date'),
                    subtitle: Text(_followUpDate != null 
                        ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}' 
                        : 'No follow up scheduled'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save Prescription'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
