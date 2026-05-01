import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/core/config/supabase_config.dart';
import '../models/scan.dart';
import '../utils/provider_error_utils.dart';
import '../service/dental_disease_detection_service.dart';
import '../utils/image_annotation_utils.dart';

class ScanProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Scan records are stored in Firestore, images in Supabase Storage

  List<Scan> _scans = [];
  bool _loading = false;
  String? _error;

  // Filters
  String? _filterPatientId;
  bool? _filterCavityStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<Scan> get scans => _getFilteredScans();
  List<Scan> get allScans => List.unmodifiable(_scans);
  List<Scan> get recentScans {
    final sorted = List<Scan>.from(_scans)
      ..sort((a, b) => b.scanDate.compareTo(a.scanDate));
    return sorted.take(5).toList();
  }

  bool get loading => _loading;
  String? get error => _error;
  int get totalScans => _scans.length;
  int get cavitiesDetected => _scans.where((scan) => scan.hasCavity).length;
  int get healthyScans => _scans.where((scan) => !scan.hasCavity).length;

  String? get filterPatientId => _filterPatientId;
  bool? get filterCavityStatus => _filterCavityStatus;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  ScanProvider() {
    fetchScans();
  }

  // Fetch all scans from Firestore
  Future<void> fetchScans() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('scans')
          .orderBy('scanDate', descending: true)
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      _scans =
          querySnapshot.docs.map((doc) => Scan.fromFirestore(doc)).toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to fetch scans. Please try again.',
      );
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching scans: $e');
    }
  }

  // Listen to real-time updates from Firestore
  void listenToScans() {
    try {
      _firestore
          .collection('scans')
          .orderBy('scanDate', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _scans = snapshot.docs.map((doc) => Scan.fromFirestore(doc)).toList();
          notifyListeners();
        },
        onError: (e) {
          _error = ProviderErrorUtils.mapErrorMessage(
            e,
            fallback: 'Unable to sync scans right now.',
          );
          notifyListeners();
          debugPrint('Error listening to scans: $e');
        },
      );
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to initialize scan updates.',
      );
      notifyListeners();
      debugPrint('Failed to initialize scan listener: $e');
    }
  }

  // Upload scan image to Firebase Storage and save scan data to Firestore
  // Returns a map with 'scanId' and 'imageUrl' on success
  Future<Map<String, String>?> uploadScan({
    required String patientId,
    required String patientName,
    required String toothNumber,
    required String notes,
    dynamic imageFile, // Can be File or Uint8List for web
    String? cavityStatus, // Real diagnosis from YOLO (e.g. "Caries", "Healthy")
    double? confidence, // Real confidence from YOLO (0-100)
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      String imageUrl = '';
      String finalStatus = cavityStatus ?? 'Pending';
      double finalConfidence = confidence ?? 0.0;

      if (imageFile != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'scan_$timestamp.png'; // PNG for annotations

        Uint8List bytes;
        if (imageFile is Uint8List) {
          bytes = imageFile;
        } else if (imageFile is File) {
          bytes = await imageFile.readAsBytes();
        } else {
          throw Exception('Unsupported image type');
        }

        // 1. Perform AI Detection
        try {
          final detection = await DentalDetectionApiService.runDetection(
            imageBytes: bytes,
            filename: fileName,
          );

          // Use backend-provided annotated image if available
          if (detection.annotatedImageBase64.isNotEmpty) {
            try {
              bytes = base64Decode(detection.annotatedImageBase64);
            } catch (e) {
              debugPrint('Failed to decode backend annotated image: $e');
            }
          } else if (detection.detections.isNotEmpty) {
            // Fallback to local rendering if backend image is missing
            final annotations = detection.detections.map((d) {
              return {
                'bbox': [
                  d.boundingBox.x1,
                  d.boundingBox.y1,
                  d.boundingBox.width,
                  d.boundingBox.height
                ],
                'label': d.label,
              };
            }).toList();

            bytes = await ImageAnnotationUtils.renderAnnotatedImage(
                bytes, annotations);
          }

          // Update status and confidence from AI
          if (detection.detections.isNotEmpty) {
            finalStatus = detection.detections.length > 1
                ? '${detection.detections.length} Findings'
                : detection.detections.first.label;
            finalConfidence = detection.detections.first.confidence * 100;
          } else {
            finalStatus = 'Healthy';
            finalConfidence = 100.0;
          }
        } catch (e) {
          debugPrint('AI Detection failed in ScanProvider: $e');
          // Continue with original image if AI fails
        }

        // 3. Upload to Supabase Storage
        final path = 'scans/$patientId/$fileName';
        await SupabaseConfig.client.storage
            .from('Image')
            .uploadBinary(
              path,
              bytes,
              fileOptions:
                  const FileOptions(contentType: 'image/png', upsert: true),
            )
            .timeout(const Duration(seconds: 120));

        imageUrl =
            SupabaseConfig.client.storage.from('Image').getPublicUrl(path);
      }

      final newScan = Scan(
        id: '', // Will be set by Firestore
        patientId: patientId,
        patientName: patientName,
        toothNumber: toothNumber,
        imageUrl: imageUrl,
        scanDate: DateTime.now(),
        cavityStatus: finalStatus,
        confidence: finalConfidence,
        notes: notes,
      );

      final docRef = await _firestore
          .collection('scans')
          .add(newScan.toFirestore())
          .timeout(ProviderErrorUtils.requestTimeout);

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchScans();

      return {'scanId': docRef.id, 'imageUrl': imageUrl};
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to upload scan. Please try again.',
      );
      _loading = false;
      notifyListeners();
      debugPrint('Error uploading scan: $e');
      rethrow;
    }
  }

  // Fetch scans for a specific patient
  Future<List<Scan>> fetchScansForPatient(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('scans')
          .where('patientId', isEqualTo: patientId)
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      final items =
          querySnapshot.docs.map((doc) => Scan.fromFirestore(doc)).toList();
      items.sort((a, b) => b.scanDate.compareTo(a.scanDate));
      return items;
    } catch (e) {
      debugPrint('Error fetching scans for patient: $e');
      return [];
    }
  }

  // Delete a scan from Firestore and Storage
  Future<bool> deleteScan(String scanId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final scanDoc = await _firestore.collection('scans').doc(scanId).get();
      if (!scanDoc.exists) throw Exception('Scan not found');

      final data = scanDoc.data()!;
      final imageUrl = data['imageUrl'] as String?;

      // Delete from Firestore
      await _firestore.collection('scans').doc(scanId).delete();

      // Attempt to delete from Storage if imageUrl exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Extract path from public URL if possible, or just use the one we know
          // For now, let's assume images are in the 'images' bucket
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          // Supabase public URL structure: /storage/v1/object/public/bucket/path
          if (pathSegments.contains('public')) {
            final bucketIdx = pathSegments.indexOf('public') + 1;
            final path = pathSegments.sublist(bucketIdx + 1).join('/');
            await SupabaseConfig.client.storage.from('Image').remove([path]);
          }
        } catch (e) {
          debugPrint(
              'Warning: Failed to delete scan image from Supabase storage: $e');
        }
      }

      await fetchScans();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  List<Scan> _getFilteredScans() {
    var filtered = List<Scan>.from(_scans);

    if (_filterPatientId != null) {
      filtered =
          filtered.where((scan) => scan.patientId == _filterPatientId).toList();
    }

    if (_filterCavityStatus != null) {
      final statusString = _filterCavityStatus! ? 'Cavity' : 'Healthy';
      filtered =
          filtered.where((scan) => scan.cavityStatus == statusString).toList();
    }

    if (_filterStartDate != null) {
      filtered = filtered
          .where((scan) => scan.scanDate.isAfter(_filterStartDate!))
          .toList();
    }

    if (_filterEndDate != null) {
      filtered = filtered
          .where((scan) => scan.scanDate.isBefore(_filterEndDate!))
          .toList();
    }

    filtered.sort((a, b) => b.scanDate.compareTo(a.scanDate));
    return List.unmodifiable(filtered);
  }

  void setPatientFilter(String? patientId) {
    _filterPatientId = patientId;
    notifyListeners();
  }

  void setCavityStatusFilter(bool? hasCavity) {
    _filterCavityStatus = hasCavity;
    notifyListeners();
  }

  void setStartDateFilter(DateTime? date) {
    _filterStartDate = date;
    notifyListeners();
  }

  void setEndDateFilter(DateTime? date) {
    _filterEndDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _filterPatientId = null;
    _filterCavityStatus = null;
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }
}
