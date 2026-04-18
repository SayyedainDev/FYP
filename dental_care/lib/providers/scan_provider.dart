import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
// Supabase removed
import '../models/scan.dart';
import '../utils/provider_error_utils.dart';

class ScanProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Supabase removed — implement Firebase Storage uploads when needed

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

      // Upload image to storage if provided.
      // NOTE: Supabase support was removed; implement Firebase Storage upload here.
      if (imageFile != null) {
        final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Normalize image bytes for potential upload (actual upload to be
        // implemented with Firebase Storage). We only read bytes here so
        // downstream code can use them when upload is implemented.
        final Uint8List bytes;
        if (imageFile is Uint8List) {
          bytes = imageFile;
        } else if (imageFile is File) {
          bytes = await imageFile
              .readAsBytes()
              .timeout(ProviderErrorUtils.requestTimeout);
        } else if (imageFile is String) {
          final file = File(imageFile);
          if (await file.exists().timeout(ProviderErrorUtils.requestTimeout)) {
            bytes = await file
                .readAsBytes()
                .timeout(ProviderErrorUtils.requestTimeout);
          } else {
            throw Exception('File path does not exist');
          }
        } else {
          try {
            bytes = imageFile as Uint8List;
          } catch (_) {
            throw Exception('Unsupported image type for upload');
          }
        }

        debugPrint(
            'ScanProvider: upload requested but Supabase removed. Implement Firebase Storage upload. file=$fileName bytes=${bytes.length}');
        imageUrl = '';
      }

      // Use real detection results when provided; otherwise mark as pending
      final effectiveStatus = cavityStatus ?? 'Pending Analysis';
      final effectiveConfidence = confidence ?? 0.0;

      final newScan = Scan(
        id: '', // Will be set by Firestore
        patientId: patientId,
        patientName: patientName,
        toothNumber: toothNumber,
        imageUrl: imageUrl,
        scanDate: DateTime.now(),
        cavityStatus: effectiveStatus,
        confidence: effectiveConfidence,
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
          .orderBy('scanDate', descending: true)
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      return querySnapshot.docs.map((doc) => Scan.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching scans for patient: $e');
      return [];
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
