import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import '../../../models/scan_model.dart';

class ScanListPane extends ConsumerStatefulWidget {
  final AsyncValue<List<ScanModel>> scansAsync;
  final String? selectedId;
  final Function(String) onSelect;

  const ScanListPane({
    super.key,
    required this.scansAsync,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  ConsumerState<ScanListPane> createState() => _ScanListPaneState();
}

class _ScanListPaneState extends ConsumerState<ScanListPane> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patient or tooth...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onChanged: (val) {
                    // debounce and search
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Healthy', false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Analyzed', false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Prescribed', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: widget.scansAsync.when(
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Failed to load scans\n$err', textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (scans) {
                if (scans.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No scans yet.\nStart by uploading an X-ray\nin Disease Detection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      final scan = scans[index];
                      final isSelected = scan.id == widget.selectedId;

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 20.0,
                          child: FadeInAnimation(
                            child: _ScanCard(
                              scan: scan,
                              isSelected: isSelected,
                              onTap: () => widget.onSelect(scan.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {},
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanModel scan;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScanCard({
    required this.scan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: isSelected ? 1.5 : 0.5,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Hero(
                  tag: 'xray_${scan.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.black87,
                      child: scan.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: scan.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey.shade800,
                                highlightColor: Colors.grey.shade600,
                                child: Container(color: Colors.black),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54),
                            )
                          : const Icon(Icons.image, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy · HH:mm').format(scan.scanDate),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      // Badges row
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _StatusBadge(scan: scan),
                          if (scan.findingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '${scan.findingCount} findings',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ScanModel scan;

  const _StatusBadge({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scan.statusBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scan.statusColor.withOpacity(0.3)),
      ),
      child: Text(
        scan.statusLabel,
        style: TextStyle(
          color: scan.statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
