import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/case.dart';

class CaseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Case> _cases = [];
  bool _loading = false;
  String? _error;

  // Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  CaseProvider() {
    // Fetch cases if user already logged in and listen for auth changes
    fetchCases();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        fetchCases();
        listenToCases();
      } else {
        _cases = [];
        notifyListeners();
      }
    });
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
          .orderBy('caseDate', descending: true)
          .get();

      _cases = querySnapshot.docs
          .map((doc) => Case.fromFirestore(doc))
          .toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch cases: $e';
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
      _firestore
          .collection('cases')
          .where('dentistUid', isEqualTo: uid)
          .orderBy('caseDate', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _cases = snapshot.docs
                  .map((doc) => Case.fromFirestore(doc))
                  .toList();
              notifyListeners();
            },
            onError: (e) {
              _error = 'Error listening to cases: $e';
              notifyListeners();
              debugPrint('Error listening to cases: $e');
            },
          );
    } catch (e) {
      _error = 'Failed to initialize cases listener: $e';
      notifyListeners();
      debugPrint('Failed to initialize cases listener: $e');
    }
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
    required List<dynamic>
    imageFiles, // List of image bytes (Uint8List for web) or File
    String notes = '',
  }) async {
    try {
      final uid = _uid;
      if (uid == null) {
        _error = 'User not authenticated';
        notifyListeners();
        return null;
      }

      _loading = true;
      _error = null;
      notifyListeners();

      List<String> imageUrls = [];

      // Reserve a case id so uploads can include patientId/caseId path
      final caseId = _firestore.collection('cases').doc().id;

      // Upload each image to Firebase Storage
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = _storage.ref().child(
          'cases/$patientId/$caseId/$fileName',
        );

        if (imageFile is Uint8List) {
          await storageRef.putData(
            imageFile,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else if (imageFile is String) {
          // treat as file path
          final file = File(imageFile);
          if (await file.exists()) {
            await storageRef.putFile(file);
          }
        } else if (imageFile is File) {
          await storageRef.putFile(imageFile);
        } else {
          // attempt to cast to bytes
          try {
            final bytes = imageFile as Uint8List;
            await storageRef.putData(bytes);
          } catch (_) {
            throw Exception('Unsupported image type for case upload');
          }
        }

        final downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Create initial analysis results with "Pending" status
      // TODO: Replace this with actual API call results once Flask integration is complete
      final initialAnalysisResults = {
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
        analysisResults: initialAnalysisResults,
        notes: notes,
      );

      final caseData = newCase.toFirestore();
      caseData['dentistUid'] = uid;

      // Use reserved caseId so document path is deterministic
      await _firestore.collection('cases').doc(caseId).set(caseData);

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchCases();

      return caseId;
    } catch (e) {
      _error = 'Failed to create case: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error creating case: $e');
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
      });

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchCases();
    } catch (e) {
      _error = 'Failed to update case analysis: $e';
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
          .orderBy('caseDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Case.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching cases for patient: $e');
      return [];
    }
  }

  // Filter logic
  List<Case> _getFilteredCases() {
    var filtered = List<Case>.from(_cases);

    if (_filterPatientId != null) {
      filtered = filtered
          .where((c) => c.patientId == _filterPatientId)
          .toList();
    }

    if (_filterCaseStatus != null) {
      filtered = filtered
          .where((c) => c.caseStatus == _filterCaseStatus)
          .toList();
    }

    if (_filterStartDate != null) {
      filtered = filtered
          .where((c) => c.caseDate.isAfter(_filterStartDate!))
          .toList();
    }

    if (_filterEndDate != null) {
      filtered = filtered
          .where((c) => c.caseDate.isBefore(_filterEndDate!))
          .toList();
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
      });

      // Update local cache
      final index = _cases.indexWhere((c) => c.id == caseId);
      if (index != -1) {
        await fetchCases(); // Refresh to get updated data
      }

      return true;
    } catch (e) {
      _error = 'Failed to update case: $e';
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

      // Delete images from Firebase Storage
      for (String imageUrl in caseToDelete.imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      // Delete case from Firestore
      await _firestore.collection('cases').doc(caseId).delete();

      // Update local cache
      _cases.removeWhere((c) => c.id == caseId);
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to delete case: $e';
      debugPrint('Error deleting case: $e');
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
      });

      // Update local cache
      await fetchCases();

      return true;
    } catch (e) {
      _error = 'Failed to archive case: $e';
      debugPrint('Error archiving case: $e');
      notifyListeners();
      return false;
    }
  }
}
