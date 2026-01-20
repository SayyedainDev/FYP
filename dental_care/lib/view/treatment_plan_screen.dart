import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/treatment_plan.dart';
import '../providers/treatment_plan_provider.dart';

class TreatmentPlanScreen extends StatefulWidget {
  const TreatmentPlanScreen({Key? key}) : super(key: key);

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Plans'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlanDialog(),
          ),
        ],
      ),
      body: Consumer<TreatmentPlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = planProvider.activePlans;

          return plans.isEmpty
              ? Center(
                  child: Text(
                    'No active treatment plans',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    return _buildTreatmentPlanCard(plans[index]);
                  },
                );
        },
      ),
    );
  }

  Widget _buildTreatmentPlanCard(TreatmentPlan plan) {
    final priorityColor = _getPriorityColor(plan.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(plan.title),
        subtitle: Text(
          'Progress: ${plan.progressPercentage}%',
          style: const TextStyle(fontSize: 12),
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${plan.progressPercentage}%',
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Status', plan.status),
                _buildInfoRow('Priority', plan.priority),
                _buildInfoRow(
                  'Estimated Cost',
                  '\$${plan.estimatedCost.toStringAsFixed(2)}',
                ),
                _buildInfoRow(
                  'Start Date',
                  plan.startDate.toString().split(' ')[0],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Phases',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plan.phases.length,
                  itemBuilder: (context, index) {
                    final phase = plan.phases[index];
                    return ListTile(
                      title: Text(phase.name),
                      subtitle: Text(phase.description),
                      trailing: Checkbox(
                        value: phase.isCompleted,
                        onChanged: (value) {},
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _updateProgress(plan),
                  icon: const Icon(Icons.edit),
                  label: const Text('Update Progress'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
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
