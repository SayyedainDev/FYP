import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/detection_response.dart';
import '../models/patient_scan.dart';

class ScanHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Saves a detection result to Supabase Storage and Firestore.
  Future<void> saveDetectionToPatient({
    required String patientId,
    required String dentistUid,
    required Uint8List imageBytes,
    required DetectionResponse aiResult,
    required String fileName,
    required String doctorNotes,
  }) async {
    try {
      // 1. Generate unique scan identifier
      final String scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath =
          'patients/$patientId/scans/${scanId}_$fileName';

      debugPrint('[ScanHistory] Uploading to Supabase: $storagePath');

      // 2. Upload to Supabase Storage Bucket ('IMAGE')
      await _supabase.storage.from('IMAGE').uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // 3. Get the Public URL
      final String imageUrl =
          _supabase.storage.from('IMAGE').getPublicUrl(storagePath);
      debugPrint('[ScanHistory] Supabase URL: $imageUrl');

      // 4. Map conditions/detections to a Firestore-friendly list
      final List<Map<String, dynamic>> findings = aiResult.detections.map((d) {
        return {
          'label': d.label,
          'confidence': d.confidence,
          'severity': d.severity,
          'box': [
            d.boundingBox.x1,
            d.boundingBox.y1,
            d.boundingBox.x2,
            d.boundingBox.y2
          ],
        };
      }).toList();

      // 5. Create scan record
      final scanRecord = PatientScan(
        scanId: scanId,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        notes: doctorNotes,
        detections: findings,
        dentistUid: dentistUid,
        patientId: patientId,
      );

      // 6. Save to Firestore sub-collection: patients/{patientId}/scans/{scanId}
      await _db
          .collection('patients')
          .doc(patientId)
          .collection('scans')
          .doc(scanId)
          .set(scanRecord.toFirestore());

      debugPrint('[ScanHistory] Successfully saved to Firestore');
    } catch (e) {
      debugPrint('[ScanHistory] Error: $e');
      rethrow;
    }
  }
}
