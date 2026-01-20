import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/case_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/case.dart';
import '../models/patient.dart';

/// Dashboard Screen - Exactly matches the new UI image
/// NO action buttons, ONLY stat cards and lists
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Dr. Test!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your summary for today. Calm and focused.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Stat Cards Row - ONLY stat cards, NO buttons
          Consumer2<PatientProvider, CaseProvider>(
            builder: (context, patientProvider, caseProvider, child) {
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _StatCard(
                    title: 'Total Patients',
                    value: patientProvider.totalPatients.toString(),
                    valueColor: const Color(0xFF212121),
                  ),
                  _StatCard(
                    title: 'Total Scans',
                    value: caseProvider.totalCases.toString(),
                    valueColor: const Color(0xFF212121),
                  ),
                  _StatCard(
                    title: 'Cavities Detected',
                    value: caseProvider.cavitiesDetected.toString(),
                    valueColor: const Color(0xFFFF5252),
                  ),
                  _StatCard(
                    title: 'Healthy Scans',
                    value: caseProvider.healthyCases.toString(),
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _RecentScansSection()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _PatientsSection()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScansSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CaseProvider>(
      builder: (context, caseProvider, _) {
        final recentCases = caseProvider.recentCases;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<NavigationProvider>().setPage(
                        'Scan History',
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentCases.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No scans yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recentCases
                    .map((case_) => _RecentScanItem(case_: case_))
                    .toList(),
            ],
          ),
        );
      },
    );
  }
}

class _RecentScanItem extends StatelessWidget {
  final Case case_;

  const _RecentScanItem({required this.case_});

  @override
  Widget build(BuildContext context) {
    final isCavity = case_.analysisResults['status'] == 'Cavity';
    final statusColor = isCavity
        ? const Color(0xFFFF5252)
        : const Color(0xFF4CAF50);
    final statusBgColor = isCavity
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCavity
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                case_.patientName
                    .split(' ')
                    .map((e) => e[0])
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
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
                  case_.patientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tooth #${case_.toothNumber} • ${case_.timeAgo}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isCavity ? 'Cavity' : 'Healthy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, _) {
        final recentPatients = patientProvider.getRecentPatients(limit: 3);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Patients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to add patient screen or show dialog
                      // For now, we'll just navigate to a patients page
                      context.read<NavigationProvider>().setPage('Patients');
                    },
                    child: const Text(
                      'Add Patient',
                      style: TextStyle(
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentPatients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No patients yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recentPatients
                    .map((patient) => _PatientItem(patient: patient))
                    .toList(),
            ],
          ),
        );
      },
    );
  }
}

class _PatientItem extends StatelessWidget {
  final Patient patient;

  const _PatientItem({required this.patient});

  Color _getAvatarColor() {
    final colors = [
      const Color(0xFFE3F2FD),
      const Color(0xFFFCE4EC),
      const Color(0xFFE8EAF6),
    ];
    return colors[patient.name.hashCode % colors.length];
  }

  Color _getAvatarTextColor() {
    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFFD81B60),
      const Color(0xFF5E35B1),
    ];
    return colors[patient.name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getAvatarColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                patient.initials,
                style: TextStyle(
                  color: _getAvatarTextColor(),
                  fontSize: 16,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.age} years • ${patient.gender}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
