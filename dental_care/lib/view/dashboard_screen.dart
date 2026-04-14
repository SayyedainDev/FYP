import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/responsive/app_breakpoints.dart';
import '../core/theme/app_semantic_colors.dart';
import '../providers/patient_provider.dart';
import '../providers/case_provider.dart';

/// Overview Screen - Unique, engaging layout with visual hierarchy
/// Presents data in an interesting and approachable way
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppBreakpoints.horizontalPadding(context) + 8;
    final device = AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width);
    final insightColumns = switch (device) {
      AppDeviceType.mobile => 1,
      AppDeviceType.tablet => 2,
      AppDeviceType.desktop => 4,
      AppDeviceType.largeDesktop => 4,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your practice at a glance',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Key Insights - Premium styled cards with icons
          Consumer2<PatientProvider, CaseProvider>(
            builder: (context, patientProvider, caseProvider, child) {
              return GridView.count(
                crossAxisCount: insightColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Adjusted aspect ratio to give cards more height and prevent bottom overflow
                childAspectRatio: 2.0,
                children: [
                  _InsightCard(
                    icon: Icons.people,
                    title: 'Patients',
                    value: patientProvider.totalPatients.toString(),
                    color: Theme.of(context).colorScheme.primary,
                    bgColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  _InsightCard(
                    icon: Icons.image_search,
                    title: 'Scans',
                    value: caseProvider.totalCases.toString(),
                    color: Theme.of(context).colorScheme.secondary,
                    bgColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  _InsightCard(
                    icon: Icons.warning_rounded,
                    title: 'Cavities',
                    value: caseProvider.cavitiesDetected.toString(),
                    color: Theme.of(context)
                            .extension<AppSemanticColors>()
                            ?.danger ??
                        Theme.of(context).colorScheme.error,
                    bgColor: (Theme.of(context)
                                .extension<AppSemanticColors>()
                                ?.danger ??
                            Theme.of(context).colorScheme.error)
                        .withValues(alpha: 0.12),
                  ),
                  _InsightCard(
                    icon: Icons.check_circle,
                    title: 'Healthy',
                    value: caseProvider.healthyCases.toString(),
                    color: Theme.of(context)
                            .extension<AppSemanticColors>()
                            ?.success ??
                        Theme.of(context).colorScheme.primary,
                    bgColor: (Theme.of(context)
                                .extension<AppSemanticColors>()
                                ?.success ??
                            Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.12),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),

          // Activity Feed Section - Two column layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop =
                  AppBreakpoints.fromWidth(constraints.maxWidth) ==
                          AppDeviceType.desktop ||
                      AppBreakpoints.fromWidth(constraints.maxWidth) ==
                          AppDeviceType.largeDesktop;
              if (isDesktop) {
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest scan results and updates',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              // Content
              if (recentCases.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 40,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentCases.map((case_) {
                  final isCavity = case_.analysisResults['status'] == 'Cavity';
                  final statusColor = isCavity
                      ? (Theme.of(context)
                              .extension<AppSemanticColors>()
                              ?.danger ??
                          Theme.of(context).colorScheme.error)
                      : (Theme.of(context)
                              .extension<AppSemanticColors>()
                              ?.success ??
                          Theme.of(context).colorScheme.primary);

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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tooth #${case_.toothNumber} • ${case_.timeAgo}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                                ? statusColor.withValues(alpha: 0.12)
                                : statusColor.withValues(alpha: 0.12),
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
                }),
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your recent patients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              // Content
              if (recentPatients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 40,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          'No patients yet',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentPatients.map((patient) {
                  final colors = [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                    Theme.of(context).colorScheme.tertiaryContainer,
                  ];
                  final textColors = [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patient.age} • ${patient.gender}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
