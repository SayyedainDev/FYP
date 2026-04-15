import 'package:flutter/material.dart';

import 'package:dental_care/models/assignment.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const StudentAssignmentDetailScreen({
    Key? key,
    required this.assignment,
  }) : super(key: key);

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  late TextEditingController _submissionController;

  @override
  void initState() {
    super.initState();
    _submissionController = TextEditingController();
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Subject', widget.assignment.subject),
                    _buildDetailRow('Due Date',
                        widget.assignment.dueDate.toString().split(' ')[0]),
                    _buildDetailRow('Total Marks',
                        widget.assignment.totalMarks.toStringAsFixed(0)),
                    _buildDetailRow('Status',
                        widget.assignment.isOverdue ? 'Overdue' : 'Pending'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.assignment.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!widget.assignment.isOverdue)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit Assignment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _submissionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add your submission notes here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // File picker implementation
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Attach File'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitAssignment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _submitAssignment() {
    if (_submissionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add submission notes')),
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assignment submitted successfully')),
    );

    Navigator.pop(context);
  }
}
