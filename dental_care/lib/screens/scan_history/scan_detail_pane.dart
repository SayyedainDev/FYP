import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../providers/scan_history_provider.dart';

import '../../utils/finding_colors.dart';

class ScanDetailPane extends ConsumerWidget {
  final String caseId;
  final bool showBackButton;

  const ScanDetailPane(
      {super.key, required this.caseId, this.showBackButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(caseDetailProvider(caseId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading case: $e')),
      data: (data) {
        final c = data.caseModel;
        final rx = data.prescription;

        final isNegative = !c.analysisResults.hasCavity;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Top Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () =>
                            ref.read(selectedCaseIdProvider.notifier).clear(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (showBackButton) const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF3F4F6),
                      child: Text(
                        c.patientName.isNotEmpty
                            ? c.patientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.patientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF111827)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 12, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('dd MMM yyyy').format(c.caseDate)} • Case #${c.id.substring(0, 5).toUpperCase()}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Case'),
                                  content: const Text(
                                      'Are you sure you want to delete this case?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        // NOTE: Add actual delete logic here
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text('Case deleted')));
                                        ref
                                            .read(
                                                selectedCaseIdProvider.notifier)
                                            .clear();
                                      },
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 Stat Cards
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCardDesign(
                                  title: 'AI CONFIDENCE',
                                  value:
                                      '${(c.analysisResults.confidence * 100).toStringAsFixed(0)}%',
                                  valueColor: const Color(0xFF2563EB),
                                  icon: Icons.show_chart,
                                  iconColor: const Color(0xFF93C5FD),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCardDesign(
                                  title: 'IMAGES',
                                  value: '${c.imageUrls.length}',
                                  valueColor: const Color(0xFF111827),
                                  icon: Icons.description_outlined,
                                  iconColor: const Color(0xFFE5E7EB),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCardDesign(
                                  title: 'AI FINDINGS',
                                  value:
                                      '${c.analysisResults.findingsList.length}',
                                  valueColor: const Color(0xFF111827),
                                  icon: Icons.error_outline,
                                  iconColor: const Color(0xFFFBBF24),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCardDesign(
                                  title: 'CAVITY STATUS',
                                  value: isNegative ? 'Negative' : 'Positive',
                                  valueColor: isNegative
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                  icon: null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image Viewer
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            height: 340,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFF111827), // extremely dark background
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                if (c.hasImages)
                                  Center(
                                    child: InteractiveViewer(
                                      minScale: 0.5,
                                      maxScale: 5.0,
                                      child: CachedNetworkImage(
                                        imageUrl: c.imageUrls.first,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                else
                                  const Center(
                                      child: Text('No Image Available',
                                          style: TextStyle(
                                              color: Colors.white54))),

                                // Top Right Overlay Icons
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Row(
                                    children: [
                                      _buildImageOverlayIcon(Icons.fullscreen),
                                      const SizedBox(width: 8),
                                      _buildImageOverlayIcon(
                                          Icons.filter_alt_outlined),
                                    ],
                                  ),
                                ),

                                // Bottom Bar
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1F2937),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                            'DICOM Source: OPG_PANORAMIC_001',
                                            style: TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 11)),
                                        const Text(
                                            'Zoom: 100% | Contrast: Default | Brightness: 0',
                                            style: TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bottom Two Columns
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: AI Diagnostic Findings
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline,
                                              size: 18,
                                              color: Color(0xFF60A5FA)),
                                          const SizedBox(width: 8),
                                          const Text('AI Diagnostic Findings',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (c
                                          .analysisResults.findingsList.isEmpty)
                                        const Text('No findings recorded.',
                                            style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13))
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: c
                                              .analysisResults.findingsList
                                              .map((f) => _buildFindingChip(f))
                                              .toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right: Clinical Prescription
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.description_outlined,
                                              size: 18,
                                              color: Color(0xFF60A5FA)),
                                          const SizedBox(width: 8),
                                          const Text('Clinical Prescription',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (rx != null) ...[
                                        const Text('DIAGNOSIS',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF9CA3AF),
                                                letterSpacing: 0.5)),
                                        const SizedBox(height: 4),
                                        Text(rx.diagnosis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF374151),
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('PRESCRIPTION',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF9CA3AF),
                                                    letterSpacing: 0.5)),
                                            const Icon(Icons.download_rounded,
                                                size: 14,
                                                color: Color(0xFF60A5FA)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(rx.prescription,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF4B5563))),
                                        const SizedBox(height: 16),
                                        if (rx
                                            .followUpTreatment.isNotEmpty) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFFEFF6FF), // very light blue
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFBFDBFE)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                    'FOLLOW-UP TREATMENT',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF2563EB),
                                                        letterSpacing: 0.5)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  rx.followUpTreatment,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF1E3A8A),
                                                      fontStyle:
                                                          FontStyle.italic),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        if (rx.precautions.isNotEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFFFEF2F2), // very light red/pink
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFFECACA)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('PRECAUTIONS',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFDC2626),
                                                        letterSpacing: 0.5)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  rx.precautions,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF991B1B)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ] else
                                        const Text(
                                            'No clinical prescription written yet.',
                                            style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // spacing at bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFindingChip(String finding) {
    Color baseColor = findingColor(finding);
    // In light theme, a tiny tint bg with strong border and text
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.05),
        border: Border.all(color: baseColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        finding,
        style: TextStyle(
          color: baseColor.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImageOverlayIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _StatCardDesign extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _StatCardDesign({
    required this.title,
    required this.value,
    required this.valueColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor),
              ),
              if (icon != null) Icon(icon, color: iconColor, size: 24),
            ],
          ),
        ],
      ),
    );
  }
}
