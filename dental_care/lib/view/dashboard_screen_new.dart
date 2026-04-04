import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/case_provider.dart';

/// Overview Screen - Unique, engaging layout with visual hierarchy
/// Presents data in an interesting and approachable way
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your practice at a glance',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Key Insights - Premium styled cards with icons
          Consumer2<PatientProvider, CaseProvider>(
            builder: (context, patientProvider, caseProvider, child) {
              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _InsightCard(
                    icon: Icons.people,
                    title: 'Patients',
                    value: patientProvider.totalPatients.toString(),
                    color: const Color(0xFF4A90E2),
                    bgColor: const Color(0xFFE3F2FD),
                  ),
                  _InsightCard(
                    icon: Icons.image_search,
                    title: 'Scans',
                    value: caseProvider.totalCases.toString(),
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF3E8FF),
                  ),
                  _InsightCard(
                    icon: Icons.warning_rounded,
                    title: 'Cavities',
                    value: caseProvider.cavitiesDetected.toString(),
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEE2E2),
                  ),
                  _InsightCard(
                    icon: Icons.check_circle,
                    title: 'Healthy',
                    value: caseProvider.healthyCases.toString(),
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),

          // Activity Feed Section - Two column layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1000) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _ActivityFeedSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _PatientHighlightsSection()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _ActivityFeedSection(),
                    const SizedBox(height: 24),
                    _PatientHighlightsSection(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CaseProvider>(
      builder: (context, caseProvider, _) {
        final recentCases = caseProvider.recentCases;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest scan results and updates',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              // Content
              if (recentCases.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentCases.map((case_) {
                  final isCavity = case_.analysisResults['status'] == 'Cavity';
                  final statusColor = isCavity
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                case_.patientName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tooth #${case_.toothNumber} • ${case_.timeAgo}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCavity
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCavity ? 'Cavity' : 'Healthy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _PatientHighlightsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, _) {
        final recentPatients = patientProvider.getRecentPatients(limit: 5);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient List',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your recent patients',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              // Content
              if (recentPatients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No patients yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentPatients.map((patient) {
                  final colors = [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFFCE4EC),
                    const Color(0xFFE8EAF6),
                  ];
                  final textColors = [
                    const Color(0xFF1976D2),
                    const Color(0xFFD81B60),
                    const Color(0xFF5E35B1),
                  ];
                  final bgColor = colors[patient.name.hashCode % colors.length];
                  final textColor =
                      textColors[patient.name.hashCode % textColors.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              patient.initials,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Patient Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patient.age} • ${patient.gender}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}
