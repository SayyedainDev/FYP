import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// Professional Dental Disease Detection Screen
/// Integrates with Flask YOLO API for real-time disease detection
class DentalDetectionScreen extends StatefulWidget {
  const DentalDetectionScreen({super.key});

  @override
  State<DentalDetectionScreen> createState() => _DentalDetectionScreenState();
}

class _DentalDetectionScreenState extends State<DentalDetectionScreen> {
  // Configuration
  static const String _apiBaseUrl = 'http://127.0.0.1:5000';
  static const String _coordinatesEndpoint = '/coordinates';
  static const String _analyzeEndpoint = '/analyze';
  static const int _timeoutSeconds = 120;

  // Validation constraints
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png'];
  static const int _maxFileSizeBytes = 15 * 1024 * 1024; // 15MB

  // State
  final List<PlatformFile> _selectedFiles = [];
  final Map<String, double> _imageRotations = {};
  Uint8List? _annotatedImageBytes;
  Map<String, dynamic>? _analysisData;
  bool _isDetecting = false;
  bool _useMultiAngle = false;
  String? _errorMessage;
  int _currentImageIndex = 0;
  final FocusNode _keyboardFocus = FocusNode();

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
    _keyboardFocus.dispose();
    super.dispose();
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

    return null;
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
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
          _annotatedImageBytes = null;
          _analysisData = null;
          _errorMessage = null;
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

  Future<void> _runDetection() async {
    if (_selectedFiles.isEmpty || _selectedFiles[_currentImageIndex].bytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      final currentFile = _selectedFiles[_currentImageIndex];
      final uri = Uri.parse('$_apiBaseUrl$_coordinatesEndpoint');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          currentFile.bytes!,
          filename: currentFile.name,
        ),
      );
      request.fields['multi_angle'] = _useMultiAngle ? 'true' : 'false';

      final streamResponse = await request.send().timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Detection request timed out');
        },
      );

      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        setState(() {
          _annotatedImageBytes = response.bodyBytes;
          _isDetecting = false;
        });
        _showSnackBar('✓ Detection successful!', Colors.green);
      } else {
        setState(() {
          _errorMessage = 'Detection failed: HTTP ${response.statusCode}\n${response.body}';
          _isDetecting = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timeout (${_timeoutSeconds}s). Check if Flask API is running.';
        _isDetecting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e\n\nMake sure Flask API is running:\ncd model/Dental-Disease-Detection\npy app.py';
        _isDetecting = false;
      });
    }
  }

  Future<void> _runAnalysis() async {
    if (_selectedFiles.isEmpty || _selectedFiles[_currentImageIndex].bytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      final currentFile = _selectedFiles[_currentImageIndex];
      final uri = Uri.parse('$_apiBaseUrl$_analyzeEndpoint');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          currentFile.bytes!,
          filename: currentFile.name,
        ),
      );
      request.fields['multi_angle'] = _useMultiAngle ? 'true' : 'false';

      final streamResponse = await request.send().timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Analysis request timed out');
        },
      );

      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _analysisData = jsonData;
          _isDetecting = false;
        });
        _showSnackBar('✓ Analysis complete!', Colors.green);
      } else {
        setState(() {
          _errorMessage = 'Analysis failed: HTTP ${response.statusCode}\n${response.body}';
          _isDetecting = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timeout. API server may be overloaded.';
        _isDetecting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e\n\nMake sure Flask API is running.';
        _isDetecting = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _selectedFiles.clear();
      _imageRotations.clear();
      _annotatedImageBytes = null;
      _analysisData = null;
      _errorMessage = null;
      _currentImageIndex = 0;
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 900;
              if (isWideScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildLeftColumn()),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _buildRightColumn()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildLeftColumn(),
                    const SizedBox(height: 24),
                    _buildRightColumn(),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        _buildUploadCard(),
        const SizedBox(height: 24),
        _buildDetectionOptionsCard(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          _buildErrorCard(),
          const SizedBox(height: 24),
        ],
        if (_annotatedImageBytes != null)
          _buildDetectionResultCard(),
        if (_analysisData != null) ...[
          const SizedBox(height: 24),
          _buildAnalysisCard(),
        ],
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
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined, color: Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Upload X-ray Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Drag & Drop Area with Carousel
          GestureDetector(
            onTap: _isDetecting || _selectedFiles.isNotEmpty ? null : _pickImages,
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
                  height: 320,
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
                              size: 56,
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
                                    text: 'Click to upload',
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
                              'PNG, JPG accepted (max 15MB)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        )
                      : _buildImageCarousel(),
                ),
              ),
            ),
          ),

          // Add more images button
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _isDetecting ? null : _pickImages,
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

  Widget _buildImageCarousel() {
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
              // Delete button
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
              // Rotation controls
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
              // Image counter
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

  Widget _buildDetectionOptionsCard() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_outlined, color: Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 12),
              Text(
                'Detection Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: CheckboxListTile(
              title: const Text(
                'Multi-angle Detection',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Tries 0°, 90°, 180°, 270° rotations for better accuracy (slower)',
                style: TextStyle(fontSize: 12),
              ),
              value: _useMultiAngle,
              onChanged: _isDetecting
                  ? null
                  : (value) {
                      setState(() => _useMultiAngle = value ?? false);
                    },
            ),
          ),

          const SizedBox(height: 16),

          // Disease classes info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Model detects 31 dental conditions including caries, crowns, fillings, bone loss, and more.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool canDetect = _selectedFiles.isNotEmpty && !_isDetecting;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canDetect ? _runDetection : null,
                icon: _isDetecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isDetecting ? 'Detecting...' : 'Run Detection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canDetect ? _runAnalysis : null,
                icon: const Icon(Icons.bar_chart),
                label: const Text('Analyze Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5B95),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDetecting ? null : _clearAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear All'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Error',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionResultCard() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Detection Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                _annotatedImageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Annotated image shows detected conditions with bounding boxes and labels.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final overall = _analysisData!['overall'] as Map<String, dynamic>?;
    final perClass = _analysisData!['per_class'] as Map<String, dynamic>?;

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF6B5B95), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Analysis Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overall stats
          if (overall != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
               child: _buildStatRow('Total Detections', '${overall['count'] ?? 0}'),
            ),
            const SizedBox(height: 20),
          ],

          // Per-class breakdown
          if (perClass != null && perClass.isNotEmpty) ...[
            const Text(
              'Detected Conditions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            ...perClass.entries.map((entry) {
              final classData = entry.value as Map<String, dynamic>;
              final count = classData['count'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                     Text(
                       '×$count',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class _RotationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RotationButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
