/// Model classes for the Dental Disease Detection API response.
/// API: POST /coordinates -> multipart/form-data with field "image"
library;

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
  final Map<String, ClassDetail> classDetails;
  final List<Detection> detections;
  final List<ToothMapEntry> toothMap;
  final ClinicalSummary? clinicalSummary;
  final String annotatedImageBase64;

  const DetectionResponse({
    required this.success,
    required this.imageDimensions,
    required this.detectionCount,
    required this.classSummary,
    this.classDetails = const {},
    required this.detections,
    this.toothMap = const [],
    this.clinicalSummary,
    required this.annotatedImageBase64,
  });

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('[DetectionResponse] keys: ${json.keys.toList()}');

    // Parse class_summary
    final Map<String, int> classSummary = {};
    final rawSummary = json['class_summary'];
    if (rawSummary is Map) {
      for (final entry in rawSummary.entries) {
        classSummary[entry.key.toString()] = _safeInt(entry.value);
      }
    }

    // Parse class_details
    final Map<String, ClassDetail> classDetails = {};
    final rawDetails = json['class_details'];
    if (rawDetails is Map) {
      for (final entry in rawDetails.entries) {
        try {
          classDetails[entry.key.toString()] =
              ClassDetail.fromJson(_safeMap(entry.value));
        } catch (_) {}
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

    // Parse tooth_map
    final rawToothMap = json['tooth_map'];
    final List<ToothMapEntry> toothMap = [];
    if (rawToothMap is List) {
      for (final t in rawToothMap) {
        try {
          toothMap.add(ToothMapEntry.fromJson(_safeMap(t)));
        } catch (_) {}
      }
    }

    // Parse clinical_summary
    ClinicalSummary? clinicalSummary;
    if (json['clinical_summary'] != null) {
      try {
        clinicalSummary =
            ClinicalSummary.fromJson(_safeMap(json['clinical_summary']));
      } catch (_) {}
    }

    return DetectionResponse(
      success: _safeBool(json['success']),
      imageDimensions: ImageDimensions.fromJson(
        _safeMap(json['image_dimensions']),
      ),
      detectionCount: _safeInt(json['detection_count']),
      classSummary: classSummary,
      classDetails: classDetails,
      detections: detections,
      toothMap: toothMap,
      clinicalSummary: clinicalSummary,
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
  final String? id;
  final String label;
  final int classId;
  final double confidence;
  final DetectionColor color;
  final BoundingBox boundingBox;
  final NormalizedBox? normalizedBox;
  final List<SegmentationPoint> segmentation;

  // Clinical pipeline fields
  final String? severity;
  final double? involvementPercent;
  final String? parentToothId;
  final List<ProximityAlert> proximityAlerts;
  final String auditStatus;

  const Detection({
    this.id,
    required this.label,
    required this.classId,
    required this.confidence,
    required this.color,
    required this.boundingBox,
    this.normalizedBox,
    this.segmentation = const [],
    this.severity,
    this.involvementPercent,
    this.parentToothId,
    this.proximityAlerts = const [],
    this.auditStatus = 'pending',
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    // Parse segmentation polygon points
    final rawSeg = json['segmentation'];
    final List<SegmentationPoint> segPts = [];
    if (rawSeg is List) {
      for (final pt in rawSeg) {
        final m = _safeMap(pt);
        segPts.add(SegmentationPoint(
          x: _safeDouble(m['x']),
          y: _safeDouble(m['y']),
        ));
      }
    }

    // Parse proximity alerts
    final rawAlerts = json['proximity_alerts'];
    final List<ProximityAlert> alerts = [];
    if (rawAlerts is List) {
      for (final a in rawAlerts) {
        try {
          alerts.add(ProximityAlert.fromJson(_safeMap(a)));
        } catch (_) {}
      }
    }

    return Detection(
      id: json['id'] as String?,
      label: _safeString(json['label'], 'Unknown'),
      classId: _safeInt(json['class_id']),
      confidence: _safeDouble(json['confidence']),
      color: DetectionColor.fromJson(_safeMap(json['color'])),
      boundingBox: BoundingBox.fromJson(_safeMap(json['bounding_box'])),
      normalizedBox: json['normalized'] != null
          ? NormalizedBox.fromJson(_safeMap(json['normalized']))
          : null,
      segmentation: segPts,
      severity: json['severity'] as String?,
      involvementPercent: json['involvement_percent'] != null
          ? _safeDouble(json['involvement_percent'])
          : null,
      parentToothId: json['parent_tooth_id'] as String?,
      proximityAlerts: alerts,
      auditStatus: _safeString(json['audit_status'], 'pending'),
    );
  }

  /// Confidence as percentage string, e.g. "92.3%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Whether real segmentation polygon data is available from the backend.
  bool get hasSegmentation => segmentation.length >= 3;

  /// Whether this detection has any urgent proximity alerts.
  bool get hasUrgentProximity => proximityAlerts.any((a) => a.urgency != null);

  /// Whether this detection is a Progressed caries.
  bool get isProgressed => severity == 'Progressed';
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

// ─── NormalizedBox ──────────────────────────────────────────────────────────

/// Bounding box coordinates normalised to [0..1] relative to image dimensions.
class NormalizedBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const NormalizedBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory NormalizedBox.fromJson(Map<String, dynamic> json) {
    return NormalizedBox(
      x1: _safeDouble(json['x1']),
      y1: _safeDouble(json['y1']),
      x2: _safeDouble(json['x2']),
      y2: _safeDouble(json['y2']),
    );
  }
}

// ─── SegmentationPoint ──────────────────────────────────────────────────────

/// A single (x, y) point in a segmentation polygon (pixel coordinates).
class SegmentationPoint {
  final double x;
  final double y;

  const SegmentationPoint({required this.x, required this.y});
}

// ─── ClassDetail ────────────────────────────────────────────────────────────

/// Per-class aggregate info from the Flask `class_details` field.
class ClassDetail {
  final int count;
  final double maxConfidence;
  final DetectionColor color;

  const ClassDetail({
    required this.count,
    required this.maxConfidence,
    required this.color,
  });

  factory ClassDetail.fromJson(Map<String, dynamic> json) {
    return ClassDetail(
      count: _safeInt(json['count']),
      maxConfidence: _safeDouble(json['max_confidence']),
      color: DetectionColor.fromJson(_safeMap(json['color'])),
    );
  }
}

// ─── ProximityAlert ─────────────────────────────────────────────────────────

/// A proximity alert to an anatomical landmark (nerve, canal, sinus).
class ProximityAlert {
  final String landmark;
  final String? landmarkId;
  final double distancePx;
  final String? urgency;

  const ProximityAlert({
    required this.landmark,
    this.landmarkId,
    required this.distancePx,
    this.urgency,
  });

  factory ProximityAlert.fromJson(Map<String, dynamic> json) {
    return ProximityAlert(
      landmark: _safeString(json['landmark'], 'Unknown'),
      landmarkId: json['landmark_id'] as String?,
      distancePx: _safeDouble(json['distance_px']),
      urgency: json['urgency'] as String?,
    );
  }

  bool get isUrgent => urgency != null;
}

// ─── ToothMapEntry ──────────────────────────────────────────────────────────

/// A tooth in the tooth-centric map with nested conditions.
class ToothMapEntry {
  final String toothId;
  final String label;
  final double confidence;
  final BoundingBox boundingBox;
  final NormalizedBox? normalizedBox;
  final List<ToothCondition> conditions;
  final String status; // "healthy" or "affected"

  const ToothMapEntry({
    required this.toothId,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.normalizedBox,
    this.conditions = const [],
    required this.status,
  });

  factory ToothMapEntry.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'];
    final List<ToothCondition> conditions = [];
    if (rawConditions is List) {
      for (final c in rawConditions) {
        try {
          conditions.add(ToothCondition.fromJson(_safeMap(c)));
        } catch (_) {}
      }
    }

    return ToothMapEntry(
      toothId: _safeString(json['tooth_id']),
      label: _safeString(json['label']),
      confidence: _safeDouble(json['confidence']),
      boundingBox: BoundingBox.fromJson(_safeMap(json['bounding_box'])),
      normalizedBox: json['normalized'] != null
          ? NormalizedBox.fromJson(_safeMap(json['normalized']))
          : null,
      conditions: conditions,
      status: _safeString(json['status'], 'healthy'),
    );
  }

  bool get isAffected => status == 'affected';
  bool get isHealthy => status == 'healthy';
}

// ─── ToothCondition ─────────────────────────────────────────────────────────

/// A child pathology / finding nested under a tooth.
class ToothCondition {
  final String detectionId;
  final String label;
  final double confidence;
  final String? severity;
  final double? involvementPercent;

  const ToothCondition({
    required this.detectionId,
    required this.label,
    required this.confidence,
    this.severity,
    this.involvementPercent,
  });

  factory ToothCondition.fromJson(Map<String, dynamic> json) {
    return ToothCondition(
      detectionId: _safeString(json['detection_id']),
      label: _safeString(json['label']),
      confidence: _safeDouble(json['confidence']),
      severity: json['severity'] as String?,
      involvementPercent: json['involvement_percent'] != null
          ? _safeDouble(json['involvement_percent'])
          : null,
    );
  }
}

// ─── ClinicalSummary ────────────────────────────────────────────────────────

/// Top-level clinical summary: urgent findings first, then preventative.
class ClinicalSummary {
  final List<ClinicalFinding> urgentFindings;
  final List<ClinicalFinding> preventativeObservations;
  final int urgentCount;
  final int preventativeCount;
  final int healthyTeethCount;
  final int affectedTeethCount;
  final int totalTeethDetected;
  final int totalFindings;

  const ClinicalSummary({
    this.urgentFindings = const [],
    this.preventativeObservations = const [],
    this.urgentCount = 0,
    this.preventativeCount = 0,
    this.healthyTeethCount = 0,
    this.affectedTeethCount = 0,
    this.totalTeethDetected = 0,
    this.totalFindings = 0,
  });

  factory ClinicalSummary.fromJson(Map<String, dynamic> json) {
    List<ClinicalFinding> parseFindings(dynamic raw) {
      final List<ClinicalFinding> list = [];
      if (raw is List) {
        for (final f in raw) {
          try {
            list.add(ClinicalFinding.fromJson(_safeMap(f)));
          } catch (_) {}
        }
      }
      return list;
    }

    return ClinicalSummary(
      urgentFindings: parseFindings(json['urgent_findings']),
      preventativeObservations:
          parseFindings(json['preventative_observations']),
      urgentCount: _safeInt(json['urgent_count']),
      preventativeCount: _safeInt(json['preventative_count']),
      healthyTeethCount: _safeInt(json['healthy_teeth_count']),
      affectedTeethCount: _safeInt(json['affected_teeth_count']),
      totalTeethDetected: _safeInt(json['total_teeth_detected']),
      totalFindings: _safeInt(json['total_findings']),
    );
  }

  bool get hasUrgentFindings => urgentFindings.isNotEmpty;
}

// ─── ClinicalFinding ────────────────────────────────────────────────────────

/// A single finding in the clinical summary (urgent or preventative).
class ClinicalFinding {
  final String detectionId;
  final String label;
  final double confidence;
  final String? severity;
  final double? involvementPercent;
  final String? parentToothId;
  final List<String> reasons;

  const ClinicalFinding({
    required this.detectionId,
    required this.label,
    required this.confidence,
    this.severity,
    this.involvementPercent,
    this.parentToothId,
    this.reasons = const [],
  });

  factory ClinicalFinding.fromJson(Map<String, dynamic> json) {
    final rawReasons = json['reasons'];
    final List<String> reasons = [];
    if (rawReasons is List) {
      for (final r in rawReasons) {
        reasons.add(r.toString());
      }
    }

    return ClinicalFinding(
      detectionId: _safeString(json['detection_id']),
      label: _safeString(json['label']),
      confidence: _safeDouble(json['confidence']),
      severity: json['severity'] as String?,
      involvementPercent: json['involvement_percent'] != null
          ? _safeDouble(json['involvement_percent'])
          : null,
      parentToothId: json['parent_tooth_id'] as String?,
      reasons: reasons,
    );
  }
}
