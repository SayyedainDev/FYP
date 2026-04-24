import 'package:flutter/material.dart';
import '../../models/patient.dart';

class PatientListCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback? onTap;

  const PatientListCard({super.key, required this.patient, this.onTap});

  @override
  State<PatientListCard> createState() => _PatientListCardState();
}

class _PatientListCardState extends State<PatientListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: primary.withValues(alpha: 0.16),
            highlightColor: primary.withValues(alpha: 0.08),
            hoverColor: primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with gradient background
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getAvatarGradient(
                            context, widget.patient.initials),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getAvatarColor(
                            context,
                            widget.patient.initials,
                          ).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.patient.initials,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Patient Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '${widget.patient.age} yrs',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.patient.gender == 'Female'
                                        ? Icons.female
                                        : Icons.male,
                                    size: 14,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.patient.gender,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Health Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  Patient.statusColors[widget.patient.healthStatus] ?? 0xFF2196F3,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(
                                    Patient.statusColors[widget.patient.healthStatus] ?? 0xFF2196F3,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(
                                        Patient.statusColors[widget.patient.healthStatus] ?? 0xFF2196F3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.patient.healthStatus,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(
                                        Patient.statusColors[widget.patient.healthStatus] ?? 0xFF2196F3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Contact info indicator
                            if (widget.patient.contactPhone.isNotEmpty)
                              Tooltip(
                                message: widget.patient.contactPhone,
                                child: Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (widget.patient.contactEmail.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message: widget.patient.contactEmail,
                                child: Icon(
                                  Icons.email,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action indicator
                  if (_isHovered)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: colorScheme.onPrimary,
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward,
                      color: colorScheme.outline,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(BuildContext context, String initials) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primary.withValues(alpha: 0.85),
      colorScheme.secondary.withValues(alpha: 0.85),
      colorScheme.tertiary.withValues(alpha: 0.85),
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];
    final index = initials.hashCode % colors.length;
    return colors[index.abs()];
  }

  List<Color> _getAvatarGradient(BuildContext context, String initials) {
    final base = _getAvatarColor(context, initials);
    return [base.withValues(alpha: 0.9), base.withValues(alpha: 0.7)];
  }
}
