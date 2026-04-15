import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/models/assignment.dart';

class DoctorCreateAssignmentScreen extends StatefulWidget {
  const DoctorCreateAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<DoctorCreateAssignmentScreen> createState() =>
      _DoctorCreateAssignmentScreenState();
}

class _DoctorCreateAssignmentScreenState
    extends State<DoctorCreateAssignmentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _subjectController;
  late TextEditingController _marksController;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _subjectController = TextEditingController();
    _marksController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Assignment Title',
              hint: 'Enter assignment title',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Enter subject',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter assignment description',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _marksController,
              label: 'Total Marks',
              hint: 'Enter total marks',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'Due Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDueDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDueDate != null
                    ? _selectedDueDate.toString().split(' ')[0]
                    : 'Select Due Date',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Create Assignment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  void _createAssignment() {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _marksController.text.isEmpty ||
        _selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final instructorId = context.read<AuthProvider>().user?.uid ?? '';
    final assignment = Assignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      instructorId: instructorId,
      title: _titleController.text,
      description: _descriptionController.text,
      subject: _subjectController.text,
      dueDate: _selectedDueDate!,
      totalMarks: double.parse(_marksController.text),
      assignedTo: [], // Will be filled when assigning to students
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fileUrl: '', // Will be filled if file is uploaded
      status: 'Active',
    );

    context
        .read<AssignmentProvider>()
        .createAssignment(assignment)
        .then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create assignment')),
        );
      }
    });
  }
}
