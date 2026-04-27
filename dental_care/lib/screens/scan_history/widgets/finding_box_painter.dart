import 'package:flutter/material.dart';
import '../../../models/scan_model.dart';

class FindingBoxPainter extends CustomPainter {
  final List<ScanFinding> findings;
  final Size imageSize;     // original image size
  final Size displaySize;   // rendered widget size
  final bool showBoxes;

  FindingBoxPainter({
    required this.findings,
    required this.imageSize,
    required this.displaySize,
    required this.showBoxes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showBoxes) return;
    
    // Avoid division by zero
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    
    final scaleX = displaySize.width / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;

    for (final f in findings) {
      if (f.boxX1 == null || f.boxY1 == null || f.boxX2 == null || f.boxY2 == null) {
        continue;
      }
      
      final rect = Rect.fromLTRB(
        f.boxX1! * scaleX, 
        f.boxY1! * scaleY,
        f.boxX2! * scaleX, 
        f.boxY2! * scaleY,
      );
      
      final colorHex = f.colorHex ?? '#3b82f6';
      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      
      // Draw box
      canvas.drawRect(rect, Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);

      // Draw label pill
      final label = '${f.label} ${(f.confidence * 100).toStringAsFixed(1)}%';
      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      
      final pillRect = Rect.fromLTWH(
        rect.left, rect.top - 18, tp.width + 10, 16,
      );
      
      canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(3)),
        Paint()..color = color);
      tp.paint(canvas, Offset(pillRect.left + 5, pillRect.top + 3));
    }
  }

  @override
  bool shouldRepaint(FindingBoxPainter old) =>
    old.showBoxes != showBoxes || old.findings != findings || old.displaySize != displaySize;
}
