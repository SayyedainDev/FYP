import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';
import '../models/detection_record.dart';
import '../models/prescription_model.dart';

class DetectionRepository {
  final _firestore = FirebaseFirestore.instance;
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  // ─── IMAGES ──────────────────────────────────────────────────

  Future<String> uploadOriginalImage({
    required String detectionId,
    required Uint8List bytes,
  }) async {
    final path = 'detections/$detectionId/original.jpg';
    await _supabase.storage.from('Image').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _supabase.storage.from('Image').getPublicUrl(path);
  }

  Future<String> uploadAnnotatedImage({
    required String detectionId,
    required Uint8List bytes,
  }) async {
    final path = 'detections/$detectionId/annotated.jpg';
    await _supabase.storage.from('Image').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _supabase.storage.from('Image').getPublicUrl(path);
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
      'patient_id': patientId,
      'original_image_path': originalImagePath,
      'annotated_image_path': annotatedImagePath,
      'raw_response': rawResponse,
      'conditions_found': conditions,
      'total_detections': detections.length,
      'highest_confidence': highestConf,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };

    final docRef = _firestore.collection('dental_detections').doc(id);
    await docRef.set(data);
    final snapshot = await docRef.get();

    return DetectionRecord.fromJson({...snapshot.data()!, 'id': snapshot.id});
  }

  Future<List<DetectionRecord>> getDetectionsForPatient(
      String patientId) async {
    final snapshot = await _firestore
        .collection('dental_detections')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DetectionRecord.fromJson({...doc.data(), 'id': doc.id}))
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
    final data = {
      'patient_id': patientId,
      'detection_id': detectionId,
      'diagnosis': diagnosis,
      'medications': medications.map((m) => m.toJson()).toList(),
      'instructions': instructions,
      'follow_up_date': followUpDate != null ? Timestamp.fromDate(followUpDate) : null,
      'is_finalized': true,
      'created_at': FieldValue.serverTimestamp(),
    };

    final id = _uuid.v4();
    final docRef = _firestore.collection('prescriptions').doc(id);
    await docRef.set(data);
    final snapshot = await docRef.get();

    return PrescriptionModel.fromJson({...snapshot.data()!, 'id': snapshot.id});
  }

  Future<List<PrescriptionModel>> getPrescriptionsForPatient(
      String patientId) async {
    final snapshot = await _firestore
        .collection('prescriptions')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PrescriptionModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
