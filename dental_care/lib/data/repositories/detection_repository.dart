import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/detection_record.dart';
import '../models/prescription_model.dart';

class DetectionRepository {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ─── IMAGES ──────────────────────────────────────────────────

  /// Upload original image bytes. Returns the storage path.
  Future<String> uploadOriginalImage({
    required String detectionId,
    required Uint8List bytes,
  }) async {
    final path = 'detections/$detectionId/original.jpg';
    await _client.storage
        .from('dental-detections')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return path;
  }

  /// Upload annotated image bytes (with bounding boxes drawn). Returns path.
  Future<String> uploadAnnotatedImage({
    required String detectionId,
    required Uint8List bytes,
  }) async {
    final path = 'detections/$detectionId/annotated.jpg';
    await _client.storage
        .from('dental-detections')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return path;
  }

  // ─── DETECTIONS ───────────────────────────────────────────────

  /// Save a complete detection result linked to a patient.
  Future<DetectionRecord> saveDetection({
    required String patientId,
    required Map<String, dynamic> rawResponse,
    required String originalImagePath,
    required String annotatedImagePath,
    String? notes,
  }) async {
    final id = _uuid.v4();

    // Extract summary fields from rawResponse
    final detections = (rawResponse['detections'] as List<dynamic>? ?? []);
    final conditions = detections
        .map((d) => d['label']?.toString() ?? '')
        .toSet()
        .toList();
    final highestConf = detections.fold<double>(
      0.0,
      (prev, d) => ((d['confidence'] as num?)?.toDouble() ?? 0.0) > prev
          ? (d['confidence'] as num).toDouble()
          : prev,
    );

    final data = {
      'id': id,
      'patient_id': patientId,
      'original_image_path': originalImagePath,
      'annotated_image_path': annotatedImagePath,
      'raw_response': rawResponse,
      'conditions_found': conditions,
      'total_detections': detections.length,
      'highest_confidence': highestConf,
      'notes': notes,
    };

    final response = await _client
        .from('dental_detections')
        .insert(data)
        .select()
        .single();

    return DetectionRecord.fromJson(response);
  }

  /// Fetch all detections for a patient, newest first.
  Future<List<DetectionRecord>> getDetectionsForPatient(
      String patientId) async {
    final response = await _client
        .from('dental_detections')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DetectionRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── PRESCRIPTIONS ────────────────────────────────────────────

  Future<PrescriptionModel> savePrescription({
    required String patientId,
    required String detectionId,
    required String diagnosis,
    required List<MedicationItem> medications,
    String? instructions,
    DateTime? followUpDate,
  }) async {
    final id = _uuid.v4();

    final data = {
      'id': id,
      'patient_id': patientId,
      'detection_id': detectionId,
      'diagnosis': diagnosis,
      'medications': medications.map((m) => m.toJson()).toList(),
      'instructions': instructions,
      'follow_up_date': followUpDate?.toIso8601String().split('T').first,
      'is_finalized': true,
    };

    final response = await _client
        .from('prescriptions')
        .insert(data)
        .select()
        .single();

    return PrescriptionModel.fromJson(response);
  }

  Future<List<PrescriptionModel>> getPrescriptionsForPatient(
      String patientId) async {
    final response = await _client
        .from('prescriptions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PrescriptionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
