import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/performance_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';

class DoctorStudentListScreen extends StatefulWidget {
  const DoctorStudentListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorStudentListScreen> createState() =>
      _DoctorStudentListScreenState();
}

class _DoctorStudentListScreenState extends State<DoctorStudentListScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context
          .read<PerformanceProvider>()
          .fetchInstructorStudentsPerformance(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Students'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Consumer<PerformanceProvider>(
        builder: (context, performanceProvider, _) {
          if (performanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = performanceProvider.allStudentsPerformance;

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No students enrolled',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student: ${student.studentId}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Overall Score: ${student.overallPerformanceScore.toStringAsFixed(1)}%',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(student.performanceStatus),
                            backgroundColor:
                                _getStatusColor(student.performanceStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                              'Quizzes', '${student.totalQuizzesTaken}'),
                          _buildStatColumn('Avg Quiz',
                              '${student.averageQuizScore.toStringAsFixed(0)}%'),
                          _buildStatColumn(
                              'Assignments', '${student.assignmentsSubmitted}'),
                          _buildStatColumn('Avg Assign',
                              '${student.averageAssignmentScore.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // View student details
                          },
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
}
