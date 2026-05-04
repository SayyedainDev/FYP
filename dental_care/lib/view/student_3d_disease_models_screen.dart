import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/web_model_viewer.dart';

class Student3DDiseaseModelsScreen extends StatefulWidget {
  const Student3DDiseaseModelsScreen({super.key});

  @override
  State<Student3DDiseaseModelsScreen> createState() =>
      _Student3DDiseaseModelsScreenState();
}

class _Student3DDiseaseModelsScreenState
    extends State<Student3DDiseaseModelsScreen> {
  int _selectedIndex = 0;

  String _viewerHostUrlFor(String modelUrl) =>
      'model_viewer_host.html?model=${Uri.encodeComponent(modelUrl)}';

  static const List<_DiseaseToothModel> _models = [
    _DiseaseToothModel(
      diseaseName: 'Occlusal Cavity',
      toothName: 'Upper Left First Molar (Tooth 26)',
      severity: 'Early to Moderate',
      learningFocus:
          'Observe darkened occlusal grooves and enamel loss limited to the chewing surface.',
      modelUrl: 'disease:occlusal_cavity',
      viewerUrl: 'model_viewer_host.html',
      accent: Color(0xFFB45309),
    ),
    _DiseaseToothModel(
      diseaseName: 'Root Caries',
      toothName: 'Lower Right Canine (Tooth 43)',
      severity: 'Moderate',
      learningFocus:
          'Focus on the cervical region near the gumline where root surface demineralization begins.',
      modelUrl: 'disease:root_caries',
      viewerUrl: 'model_viewer_host.html',
      accent: Color(0xFF2563EB),
    ),
    _DiseaseToothModel(
      diseaseName: 'Periapical Infection',
      toothName: 'Upper Right Premolar (Tooth 14)',
      severity: 'Advanced',
      learningFocus:
          'Inspect root apex region to understand spread of infection and surrounding bone involvement.',
      modelUrl: 'disease:periapical_infection',
      viewerUrl: 'model_viewer_host.html',
      accent: Color(0xFFDC2626),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _models[_selectedIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3D Dental Disease Explorer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag to rotate 360 degrees and use mouse wheel or pinch to zoom in/out.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_models.length, (index) {
                    final item = _models[index];
                    final selected = index == _selectedIndex;
                    return ChoiceChip(
                      label: Text(item.diseaseName),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedIndex = index);
                      },
                      selectedColor: item.accent.withValues(alpha: 0.16),
                      side: BorderSide(
                        color: selected
                            ? item.accent
                            : colorScheme.outline.withValues(alpha: 0.4),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? item.accent : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      showCheckmark: false,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;
                    if (compact) {
                      return Column(
                        children: [
                          _buildModelCard(current),
                          const SizedBox(height: 14),
                          _buildDetailsCard(current),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildModelCard(current)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildDetailsCard(current)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelCard(_DiseaseToothModel model) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 500,
          width: double.infinity,
          child: Stack(
            children: [
              // 3D Model Viewer
              _build3DModelViewer(model),
              // Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Interactive 3D',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DModelViewer(_DiseaseToothModel model) {
    return Stack(
      children: [
        WebModelViewer(modelUrl: model.modelUrl),
        Positioned(
          bottom: 12,
          right: 12,
          child: ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(_viewerHostUrlFor(model.modelUrl));
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open Full'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(_DiseaseToothModel model) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.diseaseName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.account_tree_outlined,
              label: 'Target Tooth',
              value: model.toothName,
            ),
            const SizedBox(height: 10),
            _MetaRow(
              icon: Icons.local_hospital_outlined,
              label: 'Severity',
              value: model.severity,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: model.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: model.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                model.learningFocus,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Controls',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Click/touch and drag to rotate 360 degrees\n'
              '2. Scroll or pinch to zoom in/out\n'
              '3. Double-click/tap to reset focus',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiseaseToothModel {
  const _DiseaseToothModel({
    required this.diseaseName,
    required this.toothName,
    required this.severity,
    required this.learningFocus,
    required this.modelUrl,
    this.viewerUrl,
    required this.accent,
  });

  final String diseaseName;
  final String toothName;
  final String severity;
  final String learningFocus;
  final String modelUrl;
  final String? viewerUrl;
  final Color accent;
}
