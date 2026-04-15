import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';

class DoctorAssignmentsManagementScreen extends StatefulWidget {
  const DoctorAssignmentsManagementScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAssignmentsManagementScreen> createState() =>
      _DoctorAssignmentsManagementScreenState();
}

class _DoctorAssignmentsManagementScreenState
    extends State<DoctorAssignmentsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<AssignmentProvider>().fetchInstructorAssignments(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
        backgroundColor: Colors.green.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Submissions'),
          ],
        ),
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, _) {
          if (assignmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = assignmentProvider.assignments;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveAssignmentsList(assignments),
              _buildSubmissionsList(assignmentProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveAssignmentsList(List assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No assignments created',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: const Text('Active'),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Subject: ${assignment.subject}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${assignment.dueDate.toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.task, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Marks: ${assignment.totalMarks.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Edit assignment
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // View submissions
                        },
                        child: const Text('Submissions'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsList(dynamic assignmentProvider) {
    final submissions = assignmentProvider.submissions;

    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No submissions yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student: ${submission.studentId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Submitted: ${submission.submittedAt.toString().split(' ')[0]}',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(submission.status),
                      backgroundColor:
                          _getSubmissionStatusColor(submission.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (submission.status == 'Graded')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Marks: ${submission.marksObtained}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${submission.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (submission.status == 'Submitted')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showGradingDialog(context, submission);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Grade Submission'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGradingDialog(BuildContext context, dynamic submission) {
    final marksController = TextEditingController();
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grade Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Marks Obtained',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AssignmentProvider>().gradeAssignment(
                    submission.id,
                    double.parse(marksController.text),
                    feedbackController.text,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment graded successfully')),
              );
            },
            child: const Text('Submit Grade'),
          ),
        ],
      ),
    );
  }

  Color _getSubmissionStatusColor(String status) {
    switch (status) {
      case 'Graded':
        return Colors.green.shade100;
      case 'Submitted':
        return Colors.orange.shade100;
      case 'Late':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
