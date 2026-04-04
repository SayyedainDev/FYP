import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';

import '../models/patient.dart';
import '../provider/auth_provider.dart' as app_auth;
import '../service/ai_analysis_service.dart';

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  Patient? _selectedPatient;
  final List<PlatformFile> _selectedFiles = [];
  final _caseTitleController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _manualReviewController = TextEditingController();

  String _caseStatus = 'Uploaded';
  final Map<String, double> _imageRotations = {};

  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png'];
  static const int _maxFileSizeBytes = 8 * 1024 * 1024; // 8MB
  static const Size _minResolution = Size(512, 512);
  static const Size _maxResolution = Size(6000, 6000);

  bool _isAnalyzing = false;
  List<Patient> _cachedPatients = []; // Cache patients list
  final AiAnalysisService _aiService = DummyAiAnalysisService();

  // AI Analysis state
  bool _hasAnalyzed = false;
  Map<String, dynamic> _aiResults = {};
  int _currentImageIndex = 0; // For carousel
  final FocusNode _keyboardFocus = FocusNode();

  // Card decoration matching the target UI
  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  @override
  void dispose() {
    _caseTitleController.dispose();
    _symptomsController.dispose();
    _manualReviewController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  bool get _isStudentRole {
    final auth = Provider.of<app_auth.AuthProvider>(context, listen: false);
    return auth.userRole.toLowerCase() == 'student';
  }

  String _rotationKey(PlatformFile file) => file.identifier ?? file.name;

  double _rotationFor(PlatformFile file) =>
      _imageRotations[_rotationKey(file)] ?? 0;

  void _rotateImage(int index, double deltaDegrees) {
    final file = _selectedFiles[index];
    final key = _rotationKey(file);
    final next = ((_imageRotations[key] ?? 0) + deltaDegrees) % 360;
    setState(() {
      _imageRotations[key] = next;
    });
  }

  void _onKey(KeyEvent e) {
    if (_selectedFiles.isEmpty) return;
    final key = e.logicalKey;
    final isDown = e is KeyDownEvent;
    if (!isDown) return;

    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _currentImageIndex = (_currentImageIndex - 1).clamp(
          0,
          _selectedFiles.length - 1,
        );
      });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1).clamp(
          0,
          _selectedFiles.length - 1,
        );
      });
    } else if (key == LogicalKeyboardKey.keyR) {
      _rotateImage(_currentImageIndex, 90);
    } else if (key == LogicalKeyboardKey.keyL) {
      _rotateImage(_currentImageIndex, -90);
    } else if (key == LogicalKeyboardKey.delete) {
      _removeImage(_currentImageIndex);
    }
  }

  Future<String?> _validateImageFile(PlatformFile file) async {
    final ext = (file.extension ?? '').toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      return 'Unsupported format (${file.extension ?? ''}). Allowed: JPG, JPEG, PNG';
    }

    final size = file.size;
    if (size > _maxFileSizeBytes) {
      return 'File ${file.name} exceeds ${(_maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)}MB limit';
    }

    if (file.bytes == null) {
      return 'Missing image bytes for ${file.name}';
    }

    try {
      final image = await decodeImageFromList(file.bytes!);
      if (image.width < _minResolution.width ||
          image.height < _minResolution.height) {
        return 'Image ${file.name} is too small (< ${_minResolution.width.toInt()}px)';
      }
      if (image.width > _maxResolution.width ||
          image.height > _maxResolution.height) {
        return 'Image ${file.name} is too large (> ${_maxResolution.width.toInt()}px)';
      }
    } catch (e) {
      return 'Could not read ${file.name}: $e';
    }

    return null;
  }

  Future<void> _pickImages() async {
    if (_isStudentRole) {
      _showSnackBar(
        'Students have view-only access. Upload requires Dentist role.',
        Colors.orange,
      );
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Important for web
      );

      if (result != null) {
        final validFiles = <PlatformFile>[];
        for (final file in result.files) {
          final validation = await _validateImageFile(file);
          if (validation != null) {
            _showSnackBar(validation, Colors.red);
            continue;
          }
          validFiles.add(file);
        }

        if (validFiles.isEmpty) return;

        setState(() {
          _selectedFiles.addAll(validFiles);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking files: $e', Colors.red);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageRotations.remove(_rotationKey(_selectedFiles[index]));
      _selectedFiles.removeAt(index);
      if (_currentImageIndex >= _selectedFiles.length &&
          _selectedFiles.isNotEmpty) {
        _currentImageIndex = _selectedFiles.length - 1;
      }
    });
  }

  Future<void> _diagnoseCase() async {
    if (_isStudentRole) {
      _showSnackBar(
        'Students have view-only access. Please log in as Dentist to create cases.',
        Colors.orange,
      );
      return;
    }
    // Validation (kept from your code)
    if (_selectedPatient == null) {
      _showSnackBar('Please select a patient', Colors.red);
      return;
    }
    if (_selectedFiles.isEmpty) {
      _showSnackBar('Please upload at least one X-ray image', Colors.red);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _hasAnalyzed = false; // Reset analysis on new diagnosis
      _caseStatus = 'Under Review';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No authenticated user');

      final analyzed = await _aiService.analyze(
        imageBytes: _selectedFiles
            .where((f) => f.bytes != null)
            .map((f) => f.bytes!)
            .toList(),
        toothNumbers: '',
        caseTitle: _caseTitleController.text.trim(),
      );

      // TODO: Replace with Supabase storage integration
      final List<String> imageUrls = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final mainCaseRef = FirebaseFirestore.instance.collection('cases').doc();
      final patientCaseRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(_selectedPatient!.id)
          .collection('cases')
          .doc(mainCaseRef.id);
      final caseId = mainCaseRef.id;
      final nowTs = FieldValue.serverTimestamp();
      final caseTitle = _caseTitleController.text.trim().isEmpty
          ? 'Case for ${_selectedPatient!.name}'
          : _caseTitleController.text.trim();
      final reviewNotes = _manualReviewController.text.trim();
      final statusToSave = _caseStatus == 'Under Review'
          ? 'Completed'
          : _caseStatus;

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final fileName = '${timestamp}_image_$i.${file.extension ?? 'jpg'}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'cases/${currentUser.uid}/$caseId/$fileName',
        );

        try {
          final uploadTask = await storageRef.putData(file.bytes!);
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      final baseCaseData = {
        'id': patientCaseRef.id,
        'dentistUid': currentUser.uid,
        'patientId': _selectedPatient!.id,
        'patientName': _selectedPatient!.name,
        'caseTitle': caseTitle,
        'toothNumbers': '',
        'toothNumber': '',
        'symptoms': _symptomsController.text.trim(),
        'imageUrls': imageUrls,
        'analysisResults': analyzed,
        'caseStatus': statusToSave,
        'reviewNotes': reviewNotes,
        'caseDate': nowTs,
        'createdAt': nowTs,
        'updatedAt': nowTs,
      };

      await patientCaseRef.set(baseCaseData);
      await mainCaseRef.set(baseCaseData);

      // Update AI results state
      setState(() {
        _hasAnalyzed = true;
        _aiResults = analyzed;
        _isAnalyzing = false;
        _caseStatus = statusToSave;
        _currentImageIndex = 0; // Reset carousel to first image
      });

      _showSnackBar('Case analyzed and saved successfully!', Colors.green);
    } catch (e) {
      debugPrint('Error in diagnosis: $e');
      _showSnackBar('Failed to analyze case: $e', Colors.red);
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _clearCase() {
    setState(() {
      _selectedPatient = null;
      _selectedFiles.clear();
      _caseTitleController.clear();
      _symptomsController.clear();
      _manualReviewController.clear();
      _hasAnalyzed = false;
      _aiResults = {};
      _currentImageIndex = 0;
      _caseStatus = 'Uploaded';
      _imageRotations.clear();
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddPatientDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 900;
                  if (isWideScreen) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildCaseDetailsColumn()),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: _buildAIAnalysisColumn()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildCaseDetailsColumn(),
                        const SizedBox(height: 24),
                        _buildAIAnalysisColumn(),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REFACTORED WIDGETS ---

  Widget _buildCaseDetailsColumn() {
    // Reordered to match image
    return Column(
      children: [
        _buildUploadCard(), // Upload card is first
        const SizedBox(height: 24),
        _buildCaseDetailsCard(),
        const SizedBox(height: 24),
        _buildActionButtons(), // Kept your functional buttons
      ],
    );
  }

  Widget _buildUploadCard() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Scan / Photo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Drag & Drop Area with Carousel
          GestureDetector(
            onTap: _isAnalyzing || _selectedFiles.isNotEmpty
                ? null
                : _pickImages,
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: const Radius.circular(8),
                color: const Color(0xFFD1D5DB),
                strokeWidth: 2,
                dashPattern: const [6, 4],
                padding: EdgeInsets.zero,
              ),
              child: KeyboardListener(
                focusNode: _keyboardFocus,
                autofocus: true,
                onKeyEvent: _onKey,
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedFiles.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF6B7280),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Click to add image',
                                    style: TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(text: ' or drag and drop'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'PNG, JPG accepted (max 8MB, min 512px)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        )
                      : _buildUploadBoxCarousel(),
                ),
              ),
            ),
          ),

          // Add more images button
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _isAnalyzing ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Add More Images'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Carousel inside the upload box
  Widget _buildUploadBoxCarousel() {
    return CarouselSlider.builder(
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index, realIndex) {
        final file = _selectedFiles[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Stack(
            children: [
              // Image container
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: file.bytes != null
                      ? InteractiveViewer(
                          minScale: 0.7,
                          maxScale: 4,
                          child: Transform.rotate(
                            angle: _rotationFor(file) * math.pi / 180,
                            child: Image.memory(
                              file.bytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
              // Delete button (X) on top-right
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                right: 12,
                child: Row(
                  children: [
                    _RotationButton(
                      icon: Icons.rotate_left,
                      onTap: () => _rotateImage(index, -90),
                    ),
                    const SizedBox(width: 8),
                    _RotationButton(
                      icon: Icons.rotate_right,
                      onTap: () => _rotateImage(index, 90),
                    ),
                  ],
                ),
              ),
              // Image counter at bottom
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${index + 1} / ${_selectedFiles.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 0.85,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        initialPage: _currentImageIndex,
        onPageChanged: (index, reason) {
          setState(() {
            _currentImageIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCaseDetailsCard() {
    // Your code for this was already excellent, just minor tweaks.
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Case Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Select Patient',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showAddPatientDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Add New Patient',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Patient Dropdown
          StreamBuilder<QuerySnapshot>(
            stream: _getPatientsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _cachedPatients = snapshot.data!.docs
                    .map((doc) => Patient.fromFirestore(doc))
                    .toList();
              }
              return DropdownButtonFormField<Patient>(
                value: _selectedPatient,
                decoration: const InputDecoration(
                  hintText: 'Select an existing patient...',
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _cachedPatients.map((patient) {
                  return DropdownMenuItem<Patient>(
                    value: patient,
                    child: Text(patient.name),
                  );
                }).toList(),
                onChanged: (patient) {
                  setState(() {
                    _selectedPatient = patient;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Case Title
          TextFormField(
            controller: _caseTitleController,
            decoration: const InputDecoration(
              labelText: 'Case Title',
              hintText: 'e.g., Annual Checkup',
            ),
          ),
          const SizedBox(height: 16),

          // Symptoms / Notes
          TextFormField(
            controller: _symptomsController,
            decoration: const InputDecoration(
              labelText: 'Symptoms / Dentist Notes',
              hintText: 'Enter symptoms or notes...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Case status lifecycle
          DropdownButtonFormField<String>(
            value: _caseStatus,
            decoration: const InputDecoration(
              labelText: 'Case Status',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'Uploaded', child: Text('Uploaded')),
              DropdownMenuItem(
                value: 'Under Review',
                child: Text('Under Review'),
              ),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
            ],
            onChanged: _isAnalyzing
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _caseStatus = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Kept your buttons as they are functional
    final bool canDiagnose =
        !_isStudentRole &&
        _selectedPatient != null &&
        _selectedFiles.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: (canDiagnose && !_isAnalyzing) ? _diagnoseCase : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF4A90E2).withOpacity(0.5),
            ),
            child: _isAnalyzing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Analyze & Save Case',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: _isAnalyzing ? null : _clearCase,
          child: const Text('Clear', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildAIAnalysisColumn() {
    // Completely rebuilt to match the image
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 24),
          if (_isAnalyzing)
            _buildAILoadingState()
          else if (_hasAnalyzed && _aiResults.isNotEmpty)
            _buildAIResultState()
          else
            _buildAIEmptyState(),
          const SizedBox(height: 16),
          _buildManualReviewSection(),
        ],
      ),
    );
  }

  Widget _buildManualReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manual Review (AI placeholder)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _manualReviewController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Manual notes / review comments',
            hintText:
                'Document observations while AI module is integrated later.',
          ),
        ),
      ],
    );
  }

  Widget _buildAILoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(color: Color(0xFF4A90E2)),
          const SizedBox(height: 24),
          Text(
            'Analyzing X-ray images...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This may take a few moments. Please wait.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildAIEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.biotech_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Analysis Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload scans and fill in case details, then click "Analyze" to see the results here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildAIResultState() {
    // This is the new UI from the image
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalyzedImageCarousel(),
        const SizedBox(height: 24),
        _buildRiskAssessment(),
        const SizedBox(height: 24),
        _buildVerdictNotes(),
        const SizedBox(height: 16),
        // Add a "New Case" button to clear the results
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _clearCase,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Start New Case'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.white,
              backgroundColor: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzedImageCarousel() {
    final List<Map<String, dynamic>> annotations =
        (_aiResults['annotations'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyzed Image (${_currentImageIndex + 1} of ${_selectedFiles.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedFiles.isEmpty)
          _buildImagePlaceholder() // Failsafe
        else
          CarouselSlider.builder(
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index, realIndex) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(_selectedFiles[index].bytes!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Annotations
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        painter: _AnnotationPainter(
                          annotations: annotations,
                          // Only show annotations on the first image for this demo
                          showAnnotations: index == 0,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                ],
              );
            },
            options: CarouselOptions(
              aspectRatio: 16 / 10,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    // This matches the "Mouth Scan Placeholder" in the image
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Mouth Scan Placeholder',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskAssessment() {
    final confidence = (_aiResults['confidence'] as double?) ?? 0.0;
    final riskLabel = _aiResults['riskLabel'] as String? ?? 'No Risk Detected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Risk Assessment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Confidence Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const Text(
                    'Confidence',
                    style: TextStyle(fontSize: 14, color: Color(0xFF212121)),
                  ),
                ],
              ),
              // Risk Label Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBE6), // Yellow from image
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE58F)),
                ),
                child: Text(
                  riskLabel,
                  style: const TextStyle(
                    color: Color(0xFFD48806), // Dark yellow
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerdictNotes() {
    final notes =
        (_aiResults['verdictNotes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI-Suggested Verdict & Notes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: notes.map((note) => _buildVerdictListItem(note)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVerdictListItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF4A90E2), // Blue from image
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KEPT YOUR UTILITY WIDGETS ---

  Stream<QuerySnapshot> _getPatientsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('patients')
        .where('dentistUid', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

// Annotation Painter Class (for drawing on the image)
class _AnnotationPainter extends CustomPainter {
  final List<Map<String, dynamic>> annotations;
  final bool showAnnotations;

  _AnnotationPainter({required this.annotations, this.showAnnotations = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showAnnotations) return;

    final paintBox = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paintCircle = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ann in annotations) {
      if (ann['type'] == 'box') {
        final rectList = ann['rect'] as List<dynamic>;
        final rect = Rect.fromLTRB(
          rectList[0] * size.width,
          rectList[1] * size.height,
          rectList[2] * size.width,
          rectList[3] * size.height,
        );
        canvas.drawRect(rect, paintBox);
      } else if (ann['type'] == 'circle') {
        final centerList = ann['center'] as List<dynamic>;
        final radius = ann['radius'] as double;
        final center = Offset(
          centerList[0] * size.width,
          centerList[1] * size.height,
        );
        canvas.drawCircle(center, radius * size.width, paintCircle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Add Patient Dialog (kept exactly as you provided)
class _RotationButton extends StatelessWidget {
  const _RotationButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _AddPatientDialog extends StatefulWidget {
  const _AddPatientDialog();

  @override
  State<_AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<_AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Patient',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter patient\'s full name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF8F9FA),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Date of Birth *'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : const Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genderOptions
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Medical History Notes',
                  hintText: 'Optional medical history or notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _savePatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save Patient'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: const Color(0xFF4A90E2)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date of birth'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No authenticated user');

      final patient = Patient(
        id: '',
        dentistUid: currentUser.uid,
        name: _nameController.text.trim(),
        dob: _selectedDate!,
        gender: _selectedGender,
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('patients')
          .add(patient.toFirestore());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
