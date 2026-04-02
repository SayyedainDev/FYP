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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF4A90E2).withOpacity(0.3)
                : Colors.grey[200]!,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                        colors: _getAvatarGradient(widget.patient.initials),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getAvatarColor(
                            widget.patient.initials,
                          ).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.patient.initials,
                        style: const TextStyle(
                          color: Colors.white,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
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
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE0E6ED),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '${widget.patient.age} yrs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A90E2),
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
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE0E6ED),
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
                                    color: const Color(0xFF4A90E2),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.patient.gender,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A90E2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Contact info indicator
                            if (widget.patient.contactPhone.isNotEmpty)
                              Tooltip(
                                message: widget.patient.contactPhone,
                                child: Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            if (widget.patient.contactEmail.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message: widget.patient.contactEmail,
                                child: Icon(
                                  Icons.email,
                                  size: 16,
                                  color: Colors.grey[400],
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
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[300],
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

  Color _getAvatarColor(String initials) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF00BCD4),
      const Color(0xFF009688),
      const Color(0xFF4CAF50),
    ];
    final index = initials.hashCode % colors.length;
    return colors[index.abs()];
  }

  List<Color> _getAvatarGradient(String initials) {
    final gradients = [
      [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
      [const Color(0xFFE91E63), const Color(0xFFC2185B)],
      [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      [const Color(0xFF673AB7), const Color(0xFF512DA8)],
      [const Color(0xFF3F51B5), const Color(0xFF3949AB)],
      [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
      [const Color(0xFF009688), const Color(0xFF00796B)],
      [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
    ];
    final index = initials.hashCode % gradients.length;
    return [
      Color.fromARGB(255, 0, 0, 0),
      Color.fromARGB(255, 0, 0, 0),
    ].asMap().entries.map((e) => gradients[index.abs()][e.key]).toList();
  }
}
