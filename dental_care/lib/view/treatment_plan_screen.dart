import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_semantic_colors.dart';
import '../models/treatment_plan.dart';
import '../providers/treatment_plan_provider.dart';
import '../widgets/loaders/app_loader.dart';

class TreatmentPlanScreen extends StatefulWidget {
  const TreatmentPlanScreen({super.key});

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment Plans',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage patient treatment plans and progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreatePlanDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Treatment Plans List
            Consumer<TreatmentPlanProvider>(
              builder: (context, planProvider, _) {
                if (planProvider.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: AppLoader(message: 'Loading treatment plans...'),
                    ),
                  );
                }

                final plans = planProvider.activePlans;

                if (plans.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(64),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.medical_information_outlined,
                            size: 64,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active treatment plans',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a new treatment plan to get started',
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    return _buildTreatmentPlanCard(plans[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentPlanCard(TreatmentPlan plan) {
    final priorityColor = _getPriorityColor(plan.priority);
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: colorScheme.surface.withValues(alpha: 0)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  priorityColor.withValues(alpha: 0.2),
                  priorityColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${plan.progressPercentage}%',
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            plan.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                _buildStatusBadge(plan.status, priorityColor),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  plan.startDate.toString().split(' ')[0],
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 24),
            // Plan Details
            _buildInfoRow('Priority', plan.priority, Icons.flag, priorityColor),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Estimated Cost',
              '\$${plan.estimatedCost.toStringAsFixed(2)}',
              Icons.attach_money,
              semanticColors?.success ?? colorScheme.secondary,
            ),
            const SizedBox(height: 20),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${plan.progressPercentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: plan.progressPercentage / 100,
                    minHeight: 10,
                    backgroundColor: colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Phases
            if (plan.phases.isNotEmpty) ...[
              Text(
                'Treatment Phases',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plan.phases.length,
                itemBuilder: (context, index) {
                  final phase = plan.phases[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: phase.isCompleted
                          ? (semanticColors?.success ?? colorScheme.secondary)
                              .withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: phase.isCompleted
                            ? (semanticColors?.success ?? colorScheme.secondary)
                                .withValues(alpha: 0.35)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          phase.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: phase.isCompleted
                              ? (semanticColors?.success ??
                                  colorScheme.secondary)
                              : colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phase.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: phase.isCompleted
                                      ? (semanticColors?.success ??
                                              colorScheme.secondary)
                                          .withValues(alpha: 0.9)
                                      : colorScheme.onSurface,
                                ),
                              ),
                              if (phase.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  phase.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateProgress(plan),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Update Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: priorityColor,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    switch (priority) {
      case 'urgent':
        return semanticColors?.danger ?? colorScheme.error;
      case 'high':
        return semanticColors?.warning ?? colorScheme.tertiary;
      case 'medium':
        return semanticColors?.info ?? colorScheme.primary;
      default:
        return semanticColors?.success ?? colorScheme.secondary;
    }
  }

  void _showCreatePlanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Treatment Plan'),
        content: const SizedBox(
          height: 300,
          child: Text('Treatment plan creation form would go here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _updateProgress(TreatmentPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: StatefulBuilder(
          builder: (context, setState) {
            int progress = plan.progressPercentage;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: '$progress%',
                  onChanged: (value) =>
                      setState(() => progress = value.toInt()),
                ),
                Text('Progress: $progress%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TreatmentPlanProvider>().updateProgress(
                    plan.id,
                    plan.progressPercentage + 10,
                  );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
