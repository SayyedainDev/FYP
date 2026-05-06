import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // Ensure _selectedIndex is within valid bounds
    if (_selectedIndex >= _models.length) {
      _selectedIndex = 0;
    }
  }

  static const String _sketchfabModelPageUrl =
      'https://sketchfab.com/3d-models/tooth-decay-progression-dental-caries-4aeb54b6f5ca4615b36cbdcdf398b27b';

  static const String _sketchfabEmbedUrl =
      'https://sketchfab.com/models/4aeb54b6f5ca4615b36cbdcdf398b27b/embed?autostart=1&preload=1&transparent=1&ui_infos=0&ui_controls=0&ui_stop=0&ui_hint=0&ui_help=0&ui_settings=0&ui_watermark=0&ui_watermark_link=0&ui_vr=0&ui_fullscreen=0&ui_annotations=0&dnt=1';

  static const List<_DiseaseToothModel> _models = [
    _DiseaseToothModel(
      diseaseName: 'Occlusal Cavity',
      toothName: 'Upper Left First Molar (Tooth 26)',
      severity: 'Early to Moderate',
      learningFocus:
          'Observe darkened occlusal grooves and enamel loss limited to the chewing surface.',
      modelUrl: _sketchfabModelPageUrl,
      viewerUrl: _sketchfabEmbedUrl,
      accent: Color(0xFFB45309),
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
                if (_models.length > 1)
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
          child: _build3DModelViewer(model),
        ),
      ),
    );
  }

  Widget _build3DModelViewer(_DiseaseToothModel model) {
    return WebModelViewer(
      viewerUrl: model.viewerUrl ?? model.modelUrl,
      modelUrl: model.modelUrl,
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
