import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/performance_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'doctor_student_list_screen.dart';
import 'doctor_create_assignment_screen.dart';
import 'doctor_assignments_management_screen.dart';
import 'doctor_analytics_screen.dart';

class DoctorLMSDashboard extends StatefulWidget {
  const DoctorLMSDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorLMSDashboard> createState() => _DoctorLMSDashboardState();
}

class _DoctorLMSDashboardState extends State<DoctorLMSDashboard> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid;

    if (uid != null) {
      context
          .read<PerformanceProvider>()
          .fetchInstructorStudentsPerformance(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final instructorName = authProvider.user?.displayName ?? 'Instructor';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Dr. $instructorName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade700, Colors.green.shade900],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<PerformanceProvider>(
                        builder: (context, performanceProvider, _) {
                          final totalStudents =
                              performanceProvider.allStudentsPerformance.length;
                          final averageScore =
                              performanceProvider.getAveragePerformanceScore();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class Overview',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$totalStudents',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Total Students',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${averageScore.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Avg Score',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          // Dashboard Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsSection(context),
                  const SizedBox(height: 24),
                  _buildStudentAnalyticsWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildActionCard(
              context,
              title: 'My Students',
              icon: Icons.group,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorStudentListScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Create Assignment',
              icon: Icons.assignment_add,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorCreateAssignmentScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Manage Assignments',
              icon: Icons.assignment,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAssignmentsManagementScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Class Analytics',
              icon: Icons.bar_chart,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAnalyticsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAnalyticsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performing Students',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Consumer<PerformanceProvider>(
          builder: (context, performanceProvider, _) {
            final students =
                performanceProvider.allStudentsPerformance.take(5).toList();

            if (students.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No student data available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Student ID: ${student.studentId}'),
                    subtitle: Text(
                        'Score: ${student.overallPerformanceScore.toStringAsFixed(1)}%'),
                    trailing: Chip(
                      label: Text(student.performanceStatus),
                      backgroundColor:
                          _getStatusColor(student.performanceStatus),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Excellent':
        return Colors.green.shade100;
      case 'Good':
        return Colors.blue.shade100;
      case 'Average':
        return Colors.orange.shade100;
      default:
        return Colors.red.shade100;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
