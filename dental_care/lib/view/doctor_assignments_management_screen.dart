import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/loading_provider.dart';
import 'package:dental_care/widgets/loading_button.dart';
import 'doctor_create_assignment_screen.dart';

class DoctorAssignmentsManagementScreen extends StatefulWidget {
  const DoctorAssignmentsManagementScreen({super.key});

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
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<AssignmentProvider>().fetchInstructorAssignments(uid);
        context.read<AssignmentProvider>().fetchInstructorSubmissions(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index != 1 || _tabController.indexIsChanging) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<AssignmentProvider>().fetchInstructorSubmissions(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          splashBorderRadius: BorderRadius.circular(8),
          tabs: const [
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Active'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Submissions'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAssignmentDialog,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
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
    final colorScheme = Theme.of(context).colorScheme;

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No assignments created',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first assignment to get started',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: const Text('Active'),
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Subject: ${assignment.subject}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${assignment.dueDate.toString().split(' ')[0]}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Marks: ${assignment.totalMarks.toStringAsFixed(0)}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoctorCreateAssignmentScreen(
                                assignmentToEdit: assignment,
                              ),
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _tabController.animateTo(1);
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
    final colorScheme = Theme.of(context).colorScheme;

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
        final studentName = submission.studentName.isNotEmpty
            ? submission.studentName
            : (submission.studentId.isNotEmpty
                ? submission.studentId
                : 'Unknown Student');

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
                          studentName,
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
                // File Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attachment,
                          size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              submission.fileName.isNotEmpty
                                  ? submission.fileName
                                  : 'Submission File',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (submission.submissionNotes.isNotEmpty)
                              Text(
                                'Notes: ${submission.submissionNotes}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // View/Download Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (submission.submissionFileUrl.isNotEmpty) {
                            try {
                              await _launchUrl(submission.submissionFileUrl);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error opening file: $e')),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (submission.submissionFileUrl.isNotEmpty) {
                            try {
                              await _downloadFile(
                                submission.submissionFileUrl,
                                submission.fileName.isNotEmpty
                                    ? submission.fileName
                                    : 'submission',
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error downloading: $e')),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
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

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file')),
          );
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final link = html.AnchorElement(href: url)
        ..download = fileName
        ..target = '_blank';
      link.click();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
                labelText: 'Marks Obtained (required)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 45.5',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
                hintText: 'Provide constructive feedback...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<LoadingProvider>(
            builder: (context, loadingState, _) {
              return LoadingButton(
                isLoading: loadingState.isLoading,
                child: ElevatedButton(
                  onPressed: loadingState.isLoading
                      ? null
                      : () => loadingState.runAsyncAction(() async {
                            final marks = marksController.text.trim();
                            if (marks.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please enter marks obtained'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              return;
                            }

                            try {
                              final marksValue = double.parse(marks);
                              final feedback = feedbackController.text.trim();

                              final success = await context
                                  .read<AssignmentProvider>()
                                  .gradeAssignment(
                                    submission.id,
                                    marksValue,
                                    feedback,
                                  );

                              if (mounted) {
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Assignment graded successfully'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context
                                                .read<AssignmentProvider>()
                                                .errorMessage ??
                                            'Failed to grade assignment',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } on FormatException {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Invalid marks. Please enter a valid number'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }),
                  child: const Text('Submit Grade'),
                ),
              );
            },
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

  void _showCreateAssignmentDialog() {
    // Capture the providers from the current context BEFORE navigating,
    // because Navigator.push creates a new route tree that loses access
    // to the MultiProvider in MainLayout.
    final assignmentProvider = context.read<AssignmentProvider>();
    final authProvider = context.read<AuthProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: assignmentProvider),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const DoctorCreateAssignmentScreen(),
        ),
      ),
    ).then((_) {
      // Refresh assignments after creating new one
      final uid = authProvider.user?.uid;
      if (uid != null) {
        assignmentProvider.fetchInstructorAssignments(uid);
      }
    });
  }
}
