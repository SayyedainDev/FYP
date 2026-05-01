import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import '../../models/case_model.dart';

import '../../providers/scan_history_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/finding_colors.dart';
import 'scan_detail_pane.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  final String? initialCaseId;
  const ScanHistoryScreen({super.key, this.initialCaseId});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();

    // Support deep-linking to a specific case
    if (widget.initialCaseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCaseIdProvider.notifier).select(widget.initialCaseId!);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedCaseIdProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: isWide
          ? Row(
              children: [
                SizedBox(
                  width: 480,
                  child: _ScanListPane(selectedId: selectedId),
                ),
                const VerticalDivider(width: 0.5, thickness: 0.5),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity:
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.025, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: selectedId == null
                        ? const _EmptyDetailPane()
                        : ScanDetailPane(
                            key: ValueKey(selectedId), caseId: selectedId),
                  ),
                ),
              ],
            )
          : (selectedId == null
              ? const _ScanListPane(selectedId: null)
              : ScanDetailPane(
                  key: ValueKey(selectedId),
                  caseId: selectedId,
                  showBackButton: true,
                )),
    );
  }
}

class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.panorama_outlined, size: 64, color: AppTheme.cardBorder),
          SizedBox(height: 16),
          Text('No scan selected', style: AppTheme.heading),
          SizedBox(height: 8),
          Text('Select a scan from the logic to view details.',
              style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ScanListPane extends ConsumerWidget {
  final String? selectedId;
  const _ScanListPane({this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(filteredCasesProvider);

    return Column(
      children: [
        const _FilterBar(),
        const Divider(height: 1),
        Expanded(
          child: cases.isEmpty
              ? const _EmptyList()
              : AnimationLimiter(
                  child: ListView.separated(
                    physics: AppTheme.scrollPhysics,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = cases[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 300),
                        child: SlideAnimation(
                          verticalOffset: 20,
                          child: FadeInAnimation(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _ScanCard(
                                caseModel: c,
                                isSelected: c.id == selectedId,
                                onTap: () {
                                  ref
                                      .read(selectedCaseIdProvider.notifier)
                                      .select(c.id);
                                  // In real app, push url using go_router if using web router
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Text('No scans found matching filters', style: AppTheme.bodyMd));
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A simplified filter bar since details are long, we just do a text search
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search patient or details...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            ),
            onChanged: (q) =>
                ref.read(scanHistoryFilterProvider.notifier).setSearch(q),
          ),
          const SizedBox(height: 12),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusChip('All', null),
                SizedBox(width: 8),
                _StatusChip('Uploaded', 'Uploaded'),
                SizedBox(width: 8),
                _StatusChip('Analyzed', 'Analyzed'),
                SizedBox(width: 8),
                _StatusChip('Prescribed', 'Prescribed'),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final String label;
  final String? statusValue;
  const _StatusChip(this.label, this.statusValue);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(scanHistoryFilterProvider).statusFilter;
    final isSelected = current == statusValue;

    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB), // Tailwind blue-600
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade300)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onSelected: (_) =>
          ref.read(scanHistoryFilterProvider.notifier).setStatus(statusValue),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final CaseModel caseModel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScanCard(
      {required this.caseModel, required this.isSelected, required this.onTap});

  Color _badgeBg(String status) {
    switch (status) {
      case 'Prescribed':
        return const Color(0xFFE0E7FF);
      case 'Analyzed':
        return const Color(0xFFDCFCE7);
      case 'Uploaded':
        return const Color(0xFFFEF9C3);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _badgeText(String status) {
    switch (status) {
      case 'Prescribed':
        return const Color(0xFF1D4ED8);
      case 'Analyzed':
        return const Color(0xFF15803D);
      case 'Uploaded':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
            color: isSelected ? AppTheme.accentBlue : AppTheme.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Hero(
                  tag: 'xray_${caseModel.id}',
                  child: caseModel.hasImages
                      ? CachedNetworkImage(
                          imageUrl: caseModel.imageUrls.first,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey.shade200),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: AppTheme.cardBorder,
                          child: const Icon(Icons.image_outlined,
                              color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            caseModel.patientName,
                            style: AppTheme.heading.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM yyyy').format(caseModel.caseDate),
                          style: AppTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _badgeBg(caseModel.displayStatus),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            caseModel.displayStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _badgeText(caseModel.displayStatus),
                            ),
                          ),
                        ),
                        if (caseModel
                            .analysisResults.findingsList.isNotEmpty) ...[
                          ...caseModel.analysisResults.findingsList
                              .take(2)
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: findingBadgeBg(f),
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: findingBadgeText(f)),
                                    ),
                                  )),
                          if (caseModel.analysisResults.findingsList.length > 2)
                            Text(
                                '+${caseModel.analysisResults.findingsList.length - 2}',
                                style: AppTheme.labelSmall),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      caseModel.analysisResults.details.isNotEmpty
                          ? caseModel.analysisResults.details
                          : 'No findings available yet.',
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
