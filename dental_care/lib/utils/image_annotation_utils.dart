import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageAnnotationUtils {
  static Future<Uint8List> renderAnnotatedImage(
      Uint8List imageBytes, List<Map<String, dynamic>> annotations) async {
    // Decode image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(image.width.toDouble(), image.height.toDouble());

    // Draw original image
    canvas.drawImage(image, Offset.zero, Paint());

    // Draw annotations
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red.withOpacity(0.2);

    for (final ann in annotations) {
      final bbox = ann['bbox'] as List<dynamic>?;
      final label = ann['label'] as String? ?? 'Detection';
      if (bbox != null && bbox.length == 4) {
        final x = bbox[0].toDouble();
        final y = bbox[1].toDouble();
        final w = bbox[2].toDouble();
        final h = bbox[3].toDouble();

        // Get color based on label or default
        paint.color = Colors.red;
        if (label.toLowerCase().contains('caries')) paint.color = Colors.orange;
        if (label.toLowerCase().contains('healthy')) paint.color = Colors.green;
        fillPaint.color = paint.color.withOpacity(0.2);

        final rect = Rect.fromLTWH(x, y, w, h);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, paint);

        // Draw label text
        final textPainter = TextPainter(
          text: TextSpan(
            text: ' $label ',
            style: const TextStyle(
              color: Colors.white,
              backgroundColor: Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y - textPainter.height));
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
