import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dental_care/core/config/supabase_config.dart';

import '../models/case.dart';
import '../utils/provider_error_utils.dart';

class CaseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  // Case records are stored in Firestore, images in Supabase Storage.

  List<Case> _cases = [];
  bool _loading = false;
  String? _error;

  // Auth
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _casesSubscription;
  bool _isDisposed = false;

  // Filters
  String? _filterPatientId;
  String? _filterCaseStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';

  List<Case> get cases => _getFilteredCases();
  List<Case> get allCases => List.unmodifiable(_cases);
  List<Case> get recentCases {
    final sorted = List<Case>.from(_cases)
      ..sort((a, b) => b.caseDate.compareTo(a.caseDate));
    return sorted.take(5).toList();
  }

  bool get loading => _loading;
  String? get error => _error;
  int get totalCases => _cases.length;
  int get cavitiesDetected =>
      _cases.where((c) => c.hasCavity && c.isAnalysisComplete).length;
  int get healthyCases =>
      _cases.where((c) => !c.hasCavity && c.isAnalysisComplete).length;

  String? get filterPatientId => _filterPatientId;
  String? get filterCaseStatus => _filterCaseStatus;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;

  CaseProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    // Attach the realtime listener when a user is available. authStateChanges
    // emits the current user immediately, and the snapshot listener delivers
    // the initial data — an extra one-shot fetch would triple the reads here.
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loading = true;
        notifyListeners();
        listenToCases();
      } else {
        _casesSubscription?.cancel();
        _casesSubscription = null;
        _cases = [];
        notifyListeners();
      }
    });
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  String? get _uid => _auth.currentUser?.uid;

  // Fetch all cases from Firestore
  Future<void> fetchCases() async {
    try {
      final uid = _uid;
      if (uid == null) {
        _cases = [];
        return;
      }

      _loading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('cases')
          .where('dentistUid', isEqualTo: uid)
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      final items =
          querySnapshot.docs.map((doc) => Case.fromFirestore(doc)).toList();
      items.sort((a, b) => b.caseDate.compareTo(a.caseDate));
      _cases = items;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to fetch cases. Please try again.',
      );
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching cases: $e');
    }
  }

  // Listen to real-time updates from Firestore
  void listenToCases() {
    final uid = _uid;
    if (uid == null) return;

    try {
      _casesSubscription?.cancel();
      _casesSubscription = _firestore
          .collection('cases')
          .where('dentistUid', isEqualTo: uid)
          .snapshots()
          .listen(
        (snapshot) {
          final items =
              snapshot.docs.map((doc) => Case.fromFirestore(doc)).toList();
          items.sort((a, b) => b.caseDate.compareTo(a.caseDate));
          _cases = items;
          _loading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = ProviderErrorUtils.mapErrorMessage(
            e,
            fallback: 'Unable to sync cases right now.',
          );
          _loading = false;
          notifyListeners();
          debugPrint('Error listening to cases: $e');
        },
      );
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to initialize case updates.',
      );
      notifyListeners();
      debugPrint('Failed to initialize cases listener: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _casesSubscription?.cancel();
    _authSubscription?.cancel();
    _casesSubscription = null;
    _authSubscription = null;
    super.dispose();
  }

  // Create a new case with image uploads
  // TODO: FUTURE ENHANCEMENT - This is where we'll integrate with Flask API
  // After uploading images to Firebase Storage, we should:
  // 1. Send image URLs to Python Flask API endpoint (e.g., POST /api/analyze)
  // 2. Receive AI analysis results (cavity detection, confidence, etc.)
  // 3. Update the analysisResults field with the API response
  // For now, we're just saving with "Pending AI Analysis" status
  Future<String?> createCase({
    required String patientId,
    required String patientName,
    required String toothNumber,
    required List<dynamic> imageFiles,
    String notes = '',
    Map<String, dynamic>? initialAnalysisResults,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) {
        _error = 'Your session has expired. Please log in again.';
        notifyListeners();
        return null;
      }

      _loading = true;
      _error = null;
      notifyListeners();

      List<String> imageUrls = [];

      // Reserve a case id so uploads can include patientId/caseId path
      final caseId = _firestore.collection('cases').doc().id;

      for (var file in imageFiles) {
        if (file is Uint8List) {
          try {
            final storagePath =
                'cases/$caseId/image_${DateTime.now().millisecondsSinceEpoch}.jpg';

            await SupabaseConfig.client.storage
                .from('Image')
                .uploadBinary(
                  storagePath,
                  file,
                  fileOptions: const FileOptions(
                      contentType: 'image/jpeg', upsert: true),
                )
                .timeout(const Duration(seconds: 60));

            final url = SupabaseConfig.client.storage
                .from('Image')
                .getPublicUrl(storagePath);
            imageUrls.add(url);
          } catch (e, stack) {
            debugPrint('Error uploading image to Firebase Storage: $e\n$stack');
            throw Exception(
                'Failed to upload image. Please check your connection and try again.');
          }
        }
      }

      final analysisResults = initialAnalysisResults ??
          {
            'status': 'Pending AI Analysis',
            'hasCavity': false,
            'confidence': 0.0,
            'details': 'Analysis will be performed by AI model',
          };

      final newCase = Case(
        id: '', // Will be set by Firestore
        patientId: patientId,
        patientName: patientName,
        toothNumber: toothNumber,
        caseDate: DateTime.now(),
        imageUrls: imageUrls,
        analysisResults: analysisResults,
        notes: notes,
      );

      final caseData = newCase.toFirestore();
      caseData['dentistUid'] = uid;

      // Use reserved caseId so document path is deterministic
      await _firestore
          .collection('cases')
          .doc(caseId)
          .set(caseData)
          .timeout(ProviderErrorUtils.requestTimeout);

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchCases();

      return caseId;
    } catch (e, stack) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to create case. Please try again.',
      );
      _loading = false;
      notifyListeners();
      debugPrint('Error creating case: $e\\n$stack');
      rethrow;
    }
  }

  // Update case analysis results (to be called after AI processing)
  Future<void> updateCaseAnalysis(
    String caseId,
    Map<String, dynamic> analysisData,
  ) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('cases').doc(caseId).update({
        'analysisResults': analysisData,
      }).timeout(ProviderErrorUtils.requestTimeout);

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchCases();
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to update case analysis. Please try again.',
      );
      _loading = false;
      notifyListeners();
      debugPrint('Error updating case analysis: $e');
      rethrow;
    }
  }

  // Fetch cases for a specific patient
  Future<List<Case>> fetchCasesForPatient(String patientId) async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final querySnapshot = await _firestore
          .collection('cases')
          .where('dentistUid', isEqualTo: uid)
          .where('patientId', isEqualTo: patientId)
          .get()
          .timeout(ProviderErrorUtils.requestTimeout);

      final items =
          querySnapshot.docs.map((doc) => Case.fromFirestore(doc)).toList();
      items.sort((a, b) => b.caseDate.compareTo(a.caseDate));
      return items;
    } catch (e) {
      debugPrint('Error fetching cases for patient: $e');
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to fetch patient cases. Please try again.',
      );
      notifyListeners();
      return [];
    }
  }

  // Filter logic
  List<Case> _getFilteredCases() {
    var filtered = List<Case>.from(_cases);

    if (_filterPatientId != null) {
      filtered =
          filtered.where((c) => c.patientId == _filterPatientId).toList();
    }

    if (_filterCaseStatus != null) {
      filtered =
          filtered.where((c) => c.caseStatus == _filterCaseStatus).toList();
    }

    if (_filterStartDate != null) {
      filtered =
          filtered.where((c) => c.caseDate.isAfter(_filterStartDate!)).toList();
    }

    if (_filterEndDate != null) {
      filtered =
          filtered.where((c) => c.caseDate.isBefore(_filterEndDate!)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.patientName.toLowerCase().contains(q) ||
            c.caseTitle.toLowerCase().contains(q) ||
            c.toothNumber.toLowerCase().contains(q) ||
            c.analysisStatus.toLowerCase().contains(q) ||
            c.caseStatus.toLowerCase().contains(q);
      }).toList();
    }

    filtered.sort((a, b) => b.caseDate.compareTo(a.caseDate));
    return List.unmodifiable(filtered);
  }

  void setPatientFilter(String? patientId) {
    _filterPatientId = patientId;
    notifyListeners();
  }

  void setCaseStatusFilter(String? status) {
    _filterCaseStatus = status;
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

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearFilters() {
    _filterPatientId = null;
    _filterCaseStatus = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Update an existing case
  Future<bool> updateCase(String caseId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('cases').doc(caseId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(ProviderErrorUtils.requestTimeout);

      // Update local cache
      final index = _cases.indexWhere((c) => c.id == caseId);
      if (index != -1) {
        await fetchCases(); // Refresh to get updated data
      }

      return true;
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to update case. Please try again.',
      );
      debugPrint('Error updating case: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete a case and its images
  Future<bool> deleteCase(String caseId) async {
    try {
      // Find the case to get image URLs
      final caseToDelete = _cases.firstWhere((c) => c.id == caseId);

      // Delete images from Supabase Storage
      for (String imageUrl in caseToDelete.imageUrls) {
        try {
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.contains('public')) {
            final bucketIdx = pathSegments.indexOf('public') + 1;
            final path = pathSegments.sublist(bucketIdx + 1).join('/');
            await SupabaseConfig.client.storage.from('Image').remove([path]);
          }
        } catch (e, stack) {
          debugPrint('Error deleting image from Supabase Storage: $e\n$stack');
        }
      }

      // Delete case from Firestore
      await _firestore
          .collection('cases')
          .doc(caseId)
          .delete()
          .timeout(ProviderErrorUtils.requestTimeout);

      // Update local cache
      _cases.removeWhere((c) => c.id == caseId);
      notifyListeners();

      return true;
    } catch (e, stack) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to delete case. Please try again.',
      );
      debugPrint('Error deleting case: $e\\n$stack');
      notifyListeners();
      return false;
    }
  }

  // Archive a case (sets status to 'Archived')
  Future<bool> archiveCase(String caseId) async {
    try {
      await _firestore.collection('cases').doc(caseId).update({
        'caseStatus': 'Archived',
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(ProviderErrorUtils.requestTimeout);

      // Update local cache
      await fetchCases();

      return true;
    } catch (e) {
      _error = ProviderErrorUtils.mapErrorMessage(
        e,
        fallback: 'Failed to archive case. Please try again.',
      );
      debugPrint('Error archiving case: $e');
      notifyListeners();
      return false;
    }
  }
}
