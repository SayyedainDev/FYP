import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/case.dart';

class CaseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Case> _cases = [];
  bool _loading = false;
  String? _error;

  // Filters
  String? _filterPatientId;
  String? _filterAnalysisStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

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
  String? get filterAnalysisStatus => _filterAnalysisStatus;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  CaseProvider() {
    fetchCases();
  }

  // Fetch all cases from Firestore
  Future<void> fetchCases() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('cases')
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
    _firestore
        .collection('cases')
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
    imageFiles, // List of image bytes (Uint8List for web)
    String notes = '',
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      List<String> imageUrls = [];

      // Upload each image to Firebase Storage
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = _storage.ref().child('cases/$fileName');

        // Upload the file (imageFile should be Uint8List for web)
        await storageRef.putData(imageFile);
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

      final docRef = await _firestore
          .collection('cases')
          .add(newCase.toFirestore());

      _loading = false;
      notifyListeners();

      // Refresh the list
      await fetchCases();

      return docRef.id;
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
      final querySnapshot = await _firestore
          .collection('cases')
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

    if (_filterAnalysisStatus != null) {
      filtered = filtered
          .where((c) => c.analysisStatus == _filterAnalysisStatus)
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

    filtered.sort((a, b) => b.caseDate.compareTo(a.caseDate));
    return List.unmodifiable(filtered);
  }

  void setPatientFilter(String? patientId) {
    _filterPatientId = patientId;
    notifyListeners();
  }

  void setAnalysisStatusFilter(String? status) {
    _filterAnalysisStatus = status;
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
    _filterAnalysisStatus = null;
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }
}
