/// Model classes for the Dental Disease Detection API response.
/// API: POST /coordinates -> multipart/form-data with field "image"

import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';

// ─── Safe type helpers ──────────────────────────────────────────────────────
// The backend may return values in unexpected types (e.g. a Map where we
// expect a number). These helpers prevent "_JsonMap is not a subtype of num".

int _safeInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _safeDouble(dynamic v, [double fallback = 0.0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

String _safeString(dynamic v, [String fallback = '']) {
  if (v is String) return v;
  return fallback;
}

bool _safeBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true';
  return fallback;
}

Map<String, dynamic> _safeMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return <String, dynamic>{};
}

// ─── DetectionResponse ──────────────────────────────────────────────────────

class DetectionResponse {
  final bool success;
  final ImageDimensions imageDimensions;
  final int detectionCount;
  final Map<String, int> classSummary;
  final List<Detection> detections;
  final String annotatedImageBase64;

  const DetectionResponse({
    required this.success,
    required this.imageDimensions,
    required this.detectionCount,
    required this.classSummary,
    required this.detections,
    required this.annotatedImageBase64,
  });

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('[DetectionResponse] keys: ${json.keys.toList()}');

    // Parse class_summary — values might be int, String, or even a Map
    final Map<String, int> classSummary = {};
    final rawSummary = json['class_summary'];
    if (rawSummary is Map) {
      for (final entry in rawSummary.entries) {
        classSummary[entry.key.toString()] = _safeInt(entry.value);
      }
    }

    // Parse detections list
    final rawDetections = json['detections'];
    final List<Detection> detections = [];
    if (rawDetections is List) {
      for (final d in rawDetections) {
        try {
          detections.add(Detection.fromJson(_safeMap(d)));
        } catch (e) {
          debugPrint('[Detection] skipped malformed entry: $e');
        }
      }
    }

    return DetectionResponse(
      success: _safeBool(json['success']),
      imageDimensions: ImageDimensions.fromJson(
        _safeMap(json['image_dimensions']),
      ),
      detectionCount: _safeInt(json['detection_count']),
      classSummary: classSummary,
      detections: detections,
      annotatedImageBase64: _safeString(json['annotated_image']),
    );
  }
}

// ─── ImageDimensions ────────────────────────────────────────────────────────

class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({required this.width, required this.height});

  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(
      width: _safeInt(json['width']),
      height: _safeInt(json['height']),
    );
  }
}

// ─── Detection ──────────────────────────────────────────────────────────────

class Detection {
  final String label;
  final int classId;
  final double confidence;
  final DetectionColor color;
  final BoundingBox boundingBox;

  const Detection({
    required this.label,
    required this.classId,
    required this.confidence,
    required this.color,
    required this.boundingBox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: _safeString(json['label'], 'Unknown'),
      classId: _safeInt(json['class_id']),
      confidence: _safeDouble(json['confidence']),
      color: DetectionColor.fromJson(_safeMap(json['color'])),
      boundingBox: BoundingBox.fromJson(_safeMap(json['bounding_box'])),
    );
  }

  /// Confidence as percentage string, e.g. "92.3%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}

// ─── DetectionColor ─────────────────────────────────────────────────────────

class DetectionColor {
  final int r;
  final int g;
  final int b;

  const DetectionColor({required this.r, required this.g, required this.b});

  factory DetectionColor.fromJson(Map<String, dynamic> json) {
    return DetectionColor(
      r: _safeInt(json['r']),
      g: _safeInt(json['g']),
      b: _safeInt(json['b']),
    );
  }

  /// Convert to Flutter Color.
  Color toColor() {
    return Color(0xFF000000 | (r << 16) | (g << 8) | b);
  }
}

// ─── BoundingBox ────────────────────────────────────────────────────────────

class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: _safeDouble(json['x1']),
      y1: _safeDouble(json['y1']),
      x2: _safeDouble(json['x2']),
      y2: _safeDouble(json['y2']),
    );
  }

  double get width => (x2 - x1).abs();
  double get height => (y2 - y1).abs();
}
