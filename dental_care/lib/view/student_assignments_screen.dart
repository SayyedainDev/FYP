import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/core/theme/app_tokens.dart';
import 'student_assignment_detail_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<AssignmentProvider>().fetchStudentAssignments(uid);
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
        // Ensure there's space for the leading (hamburger) icon and avoid title overflow
        leadingWidth: 56,
        titleSpacing: 16,
        title: const Text(
          'Assignments',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.brandPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
          ],
        ),
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, _) {
          if (assignmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAssignments = assignmentProvider.assignments;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAssignmentList(
                context,
                allAssignments
                    .where((a) =>
                        !a.isOverdue &&
                        assignmentProvider.submissions
                            .where((s) =>
                                s.assignmentId == a.id &&
                                s.status != 'Submitted')
                            .isEmpty)
                    .toList(),
              ),
              _buildAssignmentList(
                context,
                allAssignments
                    .where((a) => assignmentProvider.submissions
                        .where((s) =>
                            s.assignmentId == a.id && s.status == 'Submitted')
                        .isNotEmpty)
                    .toList(),
              ),
              _buildAssignmentList(
                context,
                allAssignments
                    .where((a) => assignmentProvider.submissions
                        .where((s) =>
                            s.assignmentId == a.id && s.status == 'Graded')
                        .isNotEmpty)
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignmentList(BuildContext context, List assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No assignments here',
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
                    if (assignment.isOverdue)
                      Chip(
                        label: const Text('Overdue'),
                        backgroundColor: Colors.red.shade100,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Subject: ${assignment.subject}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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
                      'Total Marks: ${assignment.totalMarks.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentAssignmentDetailScreen(
                            assignment: assignment,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
