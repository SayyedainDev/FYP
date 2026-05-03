import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/widgets/student_screen_header.dart';
import 'student_assignment_detail_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ColorScheme get _studentColors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        final provider = context.read<AssignmentProvider>();
        await provider.fetchStudentAssignments(uid);
        await provider.fetchStudentSubmissions(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _studentColors.primary.withValues(alpha: 0.08),
              _studentColors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<AssignmentProvider>(
          builder: (context, assignmentProvider, _) {
            if (assignmentProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allAssignments = assignmentProvider.assignments;
            final studentSubmissions = assignmentProvider.submissions;

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: StudentScreenHeader(
                      title: 'Assignments',
                      subtitle:
                          'Complete assignments assigned by your instructor',
                      iconData: Icons.assignment,
                      colorScheme: _studentColors,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0),
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: _studentColors.primary,
                            labelColor: _studentColors.primary,
                            unselectedLabelColor: Colors.grey.shade600,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            tabs: const [
                              Tab(text: 'Pending'),
                              Tab(text: 'Submitted'),
                              Tab(text: 'Graded'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Pending: no submission has been made yet.
                        _buildAssignmentList(
                          context,
                          allAssignments
                              .where((a) => studentSubmissions
                                  .where((s) => s.assignmentId == a.id)
                                  .isEmpty)
                              .toList(),
                        ),
                        // Submitted: at least one submitted record exists.
                        _buildAssignmentList(
                          context,
                          allAssignments
                              .where((a) => studentSubmissions
                                  .where((s) =>
                                      s.assignmentId == a.id &&
                                      s.status == 'Submitted')
                                  .isNotEmpty)
                              .toList(),
                        ),
                        // Graded: at least one graded record exists.
                        _buildAssignmentList(
                          context,
                          allAssignments
                              .where((a) => studentSubmissions
                                  .where((s) =>
                                      s.assignmentId == a.id &&
                                      s.status == 'Graded')
                                  .isNotEmpty)
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
                      final assignmentProvider =
                          context.read<AssignmentProvider>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: assignmentProvider,
                            child: StudentAssignmentDetailScreen(
                              assignment: assignment,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _studentColors.primary,
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
