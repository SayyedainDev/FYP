// =============================================================================
// DentalDetectionScreen — Pearl AI-style Medical Imaging Viewer
//
// Architecture:
//   Upload view  → centre card for image pick + run detection
//   Result view  → [Centre: image workspace] [Right: findings panel]
//   Modal viewer → full-screen dark DICOM-style viewer with pan/zoom
//
// Annotation engine uses CustomPainter to draw organic tooth-contour
// polygon paths (not bounding boxes). Each detection's bounding box is
// transformed into an anatomically-plausible shape (tooth, lesion, filling,
// crown, etc.) using cubic Bezier curves, with prominent semi-transparent
// fills and thick colored contour outlines — matching Pearl AI's style.
// =============================================================================

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection_response.dart';
import '../service/dental_disease_detection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design System — clinical palette
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  _T._();

  // Charcoal panels
  static const Color panelBg = Color(0xFF1B1F23);
  static const Color panelSurface = Color(0xFF22272E);
  static const Color panelBorder = Color(0xFF30363D);

  // Light workspace
  static const Color workspaceBg = Color(0xFFF0F2F5);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE1E4E8);

  // Image viewport
  static const Color viewportBg = Color(0xFF1A1D21);

  // Text
  static const Color textBright = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF8B949E);
  static const Color textDim = Color(0xFF656D76);
  static const Color textDark = Color(0xFF1F2328);
  static const Color textDarkSec = Color(0xFF57606A);
  static const Color textDarkTer = Color(0xFF8C959F);

  // Accent
  static const Color accent = Color(0xFF58A6FF);
  static const Color accentDark = Color(0xFF388BFD);

  // Status
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color warningBg = Color(0xFF2A2013);
  static const Color error = Color(0xFFF85149);
  static const Color errorBg = Color(0xFF2A1215);

  // Condition-specific colours (medical standard)
  static const Color colCaries = Color(0xFFFF6B6B);
  static const Color colFilling = Color(0xFF51CF66);
  static const Color colRootCanal = Color(0xFF339AF0);
  static const Color colImpacted = Color(0xFFFCC419);
  static const Color colCalculus = Color(0xFFFF922B);
  static const Color colGingivitis = Color(0xFFE599F7);
  static const Color colCrown = Color(0xFF20C997);
  static const Color colDefault = Color(0xFF748FFC);

  // Spacing / Radii
  static const double r8 = 8;
  static const double r12 = 12;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  // Fonts
  static const String monoFont = 'monospace';
}

/// Map condition label → colour.
Color _conditionColor(String label) {
  final l = label.toLowerCase();
  if (l.contains('caries') || l.contains('cavity')) return _T.colCaries;
  if (l.contains('filling')) return _T.colFilling;
  if (l.contains('root canal') || l.contains('root_canal'))
    return _T.colRootCanal;
  if (l.contains('impacted')) return _T.colImpacted;
  if (l.contains('calculus') || l.contains('tartar')) return _T.colCalculus;
  if (l.contains('gingivitis')) return _T.colGingivitis;
  if (l.contains('crown')) return _T.colCrown;
  if (l.contains('discoloration') || l.contains('stain')) return _T.colDefault;
  return _T.colDefault;
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry Point
// ─────────────────────────────────────────────────────────────────────────────

class DentalDetectionScreen extends StatefulWidget {
  const DentalDetectionScreen({super.key});
  @override
  State<DentalDetectionScreen> createState() => _DentalDetectionScreenState();
}

class _DentalDetectionScreenState extends State<DentalDetectionScreen> {
  final _picker = ImagePicker();

  // --- server ---
  bool _serverReady = false;
  bool _checkingServer = false;
  String _serverStatus = 'Checking server…';

  // --- image ---
  Uint8List? _pickedBytes;
  String? _pickedName;

  // --- detection ---
  bool _isDetecting = false;
  String _detectStatus = '';
  DetectionResponse? _result;
  String? _errorMsg;

  // --- interaction ---
  int _highlightIdx = -1;
  bool _showLabels = true;

  // ───────────────────────────── lifecycle ─────────────────────────────────

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  // ───────────────────────────── server ────────────────────────────────────

  Future<void> _checkServer() async {
    setState(() {
      _checkingServer = true;
      _serverStatus = 'Connecting to AI server…';
    });
    try {
      await DentalDetectionApiService.waitForServerReady(
        onStatusChange: (s) {
          if (mounted) setState(() => _serverStatus = s);
        },
      );
      if (mounted) {
        setState(() {
          _serverReady = true;
          _checkingServer = false;
          _serverStatus = 'AI Server Online';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverReady = false;
          _checkingServer = false;
          _serverStatus = 'Server offline — $e';
        });
      }
    }
  }

  // ───────────────────────────── pick image ───────────────────────────────

  Future<void> _pickImage(ImageSource src) async {
    try {
      final f = await _picker.pickImage(
        source: src,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
        _pickedName = f.name;
        _result = null;
        _errorMsg = null;
        _highlightIdx = -1;
      });
    } catch (e) {
      _snack('Failed to pick image: $e');
    }
  }

  // ───────────────────────────── detection ─────────────────────────────────

  Future<void> _runDetection() async {
    if (_pickedBytes == null || !_serverReady) return;
    setState(() {
      _isDetecting = true;
      _detectStatus = 'Preparing image…';
      _errorMsg = null;
    });
    try {
      final result = await DentalDetectionApiService.runDetection(
        imageBytes: _pickedBytes!,
        filename: _pickedName ?? 'image.jpg',
        onStatusChange: (s) {
          if (mounted) setState(() => _detectStatus = s);
        },
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isDetecting = false;
          _detectStatus = '';
        });
      }
    } on DentalApiException catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _errorMsg = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _errorMsg = '$e';
        });
      }
    }
  }

  void _clearAll() {
    setState(() {
      _pickedBytes = null;
      _pickedName = null;
      _result = null;
      _errorMsg = null;
      _highlightIdx = -1;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.workspaceBg,
      body: Column(
        children: [
          _serverBanner(),
          Expanded(child: _result != null ? _resultLayout() : _uploadLayout()),
        ],
      ),
    );
  }

  // ─────────────────── server banner ──────────────────────────────────────

  Widget _serverBanner() {
    final Color bg;
    final Color fg;
    final IconData icon;
    if (_serverReady) {
      bg = const Color(0xFF1A3A1A);
      fg = _T.success;
      icon = Icons.cloud_done_rounded;
    } else if (_checkingServer) {
      bg = _T.warningBg;
      fg = _T.warning;
      icon = Icons.cloud_sync_rounded;
    } else {
      bg = _T.errorBg;
      fg = _T.error;
      icon = Icons.cloud_off_rounded;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: _T.s16, vertical: 6),
      color: bg,
      child: Row(
        children: [
          if (_checkingServer)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(icon, size: 14, color: fg),
          const SizedBox(width: _T.s8),
          Expanded(
            child: Text(
              _serverStatus,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_serverReady && !_checkingServer)
            TextButton(
              onPressed: _checkServer,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _uploadLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_T.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _T.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  size: 32,
                  color: _T.accent,
                ),
              ),
              const SizedBox(height: _T.s16),
              Text(
                'Dental Disease Detection',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _T.textDark,
                ),
              ),
              const SizedBox(height: _T.s6),
              const Text(
                'Upload a dental radiograph for AI-powered analysis',
                style: TextStyle(color: _T.textDarkSec, fontSize: 14),
              ),
              const SizedBox(height: _T.s24),

              // Drop zone / preview
              _uploadCard(),

              const SizedBox(height: _T.s16),

              // Action row
              _actionRow(),

              if (_isDetecting) ...[
                const SizedBox(height: _T.s20),
                _progressCard(),
              ],
              if (_errorMsg != null) ...[
                const SizedBox(height: _T.s16),
                _errorCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadCard() {
    return Container(
      decoration: BoxDecoration(
        color: _T.cardBg,
        border: Border.all(color: _T.cardBorder),
        borderRadius: BorderRadius.circular(_T.r12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _pickedBytes != null
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_T.r12),
                  ),
                  child: Image.memory(
                    _pickedBytes!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 360,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _T.s16,
                    vertical: _T.s12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _T.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: _T.textDarkTer,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pickedName ?? 'image.jpg',
                          style: const TextStyle(
                            color: _T.textDarkSec,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: _clearAll,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: _T.error.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () => _pickImage(ImageSource.gallery),
              borderRadius: BorderRadius.circular(_T.r12),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _T.accent.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(_T.r12),
                  color: _T.accent.withValues(alpha: 0.03),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: _T.accent.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: _T.s12),
                      Text(
                        'Click to upload a dental image',
                        style: TextStyle(
                          color: _T.accent.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'JPEG, PNG — max 10 MB',
                        style: TextStyle(color: _T.textDarkTer, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        _actionBtn(
          Icons.photo_library_outlined,
          'Gallery',
          () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(width: _T.s8),
        _actionBtn(
          Icons.camera_alt_outlined,
          'Camera',
          () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(width: _T.s12),
        Expanded(
          child: FilledButton.icon(
            onPressed: (_pickedBytes != null && _serverReady && !_isDetecting)
                ? _runDetection
                : null,
            icon: _isDetecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(_isDetecting ? 'Analyzing…' : 'Run Detection'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: _T.accentDark,
              disabledBackgroundColor: _T.accentDark.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_T.r8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        side: const BorderSide(color: _T.cardBorder),
        foregroundColor: _T.textDarkSec,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r8),
        ),
      ),
    );
  }

  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(_T.s16),
      decoration: BoxDecoration(
        color: _T.panelBg,
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _T.accent),
          ),
          const SizedBox(width: _T.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Running AI Analysis…',
                  style: TextStyle(
                    color: _T.textBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _detectStatus,
                  style: const TextStyle(color: _T.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(_T.s16),
      decoration: BoxDecoration(
        color: _T.errorBg,
        border: Border.all(color: _T.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: _T.error, size: 18),
          const SizedBox(width: _T.s12),
          Expanded(
            child: Text(
              _errorMsg!,
              style: TextStyle(
                color: _T.error.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT LAYOUT — image workspace + findings panel
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _resultLayout() {
    return LayoutBuilder(
      builder: (ctx, box) {
        final wide = box.maxWidth > 860;
        if (wide) {
          return Row(
            children: [
              Expanded(child: _imageWorkspace()),
              Container(width: 1, color: _T.panelBorder),
              SizedBox(width: 360, child: _findingsPanel()),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: _imageWorkspace()),
            Container(height: 1, color: _T.panelBorder),
            SizedBox(height: 320, child: _findingsPanel()),
          ],
        );
      },
    );
  }

  // ─────────────────── Image Workspace ────────────────────────────────────

  Widget _imageWorkspace() {
    final result = _result!;
    // Always use original clean image — CustomPainter provides annotations
    final bytes = _pickedBytes;
    if (bytes == null) return const SizedBox.shrink();

    return Container(
      color: _T.viewportBg,
      child: Column(
        children: [
          // Toolbar
          _toolbar(result),
          // Image area
          Expanded(
            child: GestureDetector(
              onTap: () => _openModal(result),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(_T.s16),
                      child: Center(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            return _AnnotatedImage(
                              imageBytes: bytes,
                              detections: result.detections,
                              imageDimensions: result.imageDimensions,
                              highlightedIdx: _highlightIdx,
                              maxSize: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              showLabels: _showLabels,
                              onTapDetection: (i) {
                                setState(() {
                                  _highlightIdx = _highlightIdx == i ? -1 : i;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Image dimensions badge (bottom-right)
                  Positioned(
                    right: _T.s12,
                    bottom: _T.s12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${result.imageDimensions.width} × ${result.imageDimensions.height} px',
                        style: const TextStyle(
                          color: _T.textMuted,
                          fontSize: 10,
                          fontFamily: _T.monoFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Enlarge hint (top-left)
                  Positioned(
                    left: _T.s12,
                    top: _T.s12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_full_rounded,
                            size: 12,
                            color: _T.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Click to enlarge',
                            style: TextStyle(color: _T.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(DetectionResponse result) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _T.s12, vertical: _T.s6),
      decoration: const BoxDecoration(
        color: _T.panelSurface,
        border: Border(bottom: BorderSide(color: _T.panelBorder)),
      ),
      child: Row(
        children: [
          // Findings count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _T.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${result.detectionCount} finding${result.detectionCount != 1 ? 's' : ''}',
              style: const TextStyle(
                color: _T.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Toggle labels
          _toolbarBtn(
            icon: _showLabels ? Icons.label : Icons.label_off_outlined,
            tooltip: _showLabels ? 'Hide labels' : 'Show labels',
            onTap: () => setState(() => _showLabels = !_showLabels),
          ),
          const SizedBox(width: 2),
          _toolbarBtn(
            icon: Icons.photo_library_outlined,
            tooltip: 'Change image',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 2),
          _toolbarBtn(
            icon: Icons.play_arrow_rounded,
            tooltip: 'Rerun detection',
            onTap: _runDetection,
          ),
          const SizedBox(width: 2),
          _toolbarBtn(
            icon: Icons.delete_outline,
            tooltip: 'Clear all',
            onTap: _clearAll,
          ),
          const SizedBox(width: 2),
          _toolbarBtn(
            icon: Icons.fullscreen_rounded,
            tooltip: 'Full screen',
            onTap: () => _openModal(result),
          ),
        ],
      ),
    );
  }

  Widget _toolbarBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: _T.textMuted),
        ),
      ),
    );
  }

  // ─────────────────── Findings Panel ─────────────────────────────────────

  Widget _findingsPanel() {
    final result = _result!;
    return Container(
      color: _T.panelBg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(_T.s16, _T.s12, _T.s16, _T.s12),
            decoration: const BoxDecoration(
              color: _T.panelSurface,
              border: Border(bottom: BorderSide(color: _T.panelBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: _T.accent,
                ),
                const SizedBox(width: _T.s8),
                const Expanded(
                  child: Text(
                    'Diagnostic Findings',
                    style: TextStyle(
                      color: _T.textBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.restart_alt_rounded, size: 14),
                  label: const Text('New Scan', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: _T.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Summary chips
          if (result.classSummary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                _T.s16,
                _T.s12,
                _T.s16,
                _T.s12,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.panelBorder)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.classSummary.entries.map((e) {
                  final c = _conditionColor(e.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: c.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          e.key,
                          style: TextStyle(
                            color: c,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '×${e.value}',
                          style: TextStyle(
                            color: c.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Detection cards
          Expanded(
            child: result.detections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 40,
                          color: _T.success,
                        ),
                        const SizedBox(height: _T.s12),
                        const Text(
                          'No findings detected',
                          style: TextStyle(
                            color: _T.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Image appears healthy',
                          style: TextStyle(color: _T.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: _T.s8),
                    itemCount: result.detections.length,
                    itemBuilder: (_, i) =>
                        _detectionCard(result.detections[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detectionCard(Detection d, int idx) {
    final isHl = _highlightIdx == idx;
    final c = _conditionColor(d.label);
    final conf = d.confidence;
    final pct = (conf * 100);

    return Material(
      color: isHl ? c.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: () =>
            setState(() => _highlightIdx = _highlightIdx == idx ? -1 : idx),
        hoverColor: c.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _T.s16,
            vertical: _T.s12,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: isHl ? c : Colors.transparent, width: 3),
              bottom: const BorderSide(color: _T.panelBorder, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + confidence badge
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                  ),
                  const SizedBox(width: _T.s8),
                  Expanded(
                    child: Text(
                      d.label,
                      style: const TextStyle(
                        color: _T.textBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: c,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: _T.monoFont,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: _T.s8),

              // Confidence bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: conf.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: _T.panelBorder,
                  color: c,
                ),
              ),

              const SizedBox(height: _T.s6),

              // Bounding box coords
              Text(
                'Box  (${d.boundingBox.x1.toStringAsFixed(0)}, ${d.boundingBox.y1.toStringAsFixed(0)})  →  (${d.boundingBox.x2.toStringAsFixed(0)}, ${d.boundingBox.y2.toStringAsFixed(0)})',
                style: const TextStyle(
                  color: _T.textDim,
                  fontSize: 10,
                  fontFamily: _T.monoFont,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── Full-screen Modal ──────────────────────────────────

  void _openModal(DetectionResponse result) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, anim, __) {
          return FadeTransition(
            opacity: anim,
            child: _FullScreenViewer(imageBytes: _pickedBytes!, result: result),
          );
        },
      ),
    );
  }
}

// =============================================================================
// _AnnotatedImage — Pearl AI-style contour overlay
//
// Renders the dental image with organic tooth-contour polygon fills and
// outlines instead of bounding boxes. Each detection is traced with
// condition-specific shapes and prominent colored strokes.
// =============================================================================

class _AnnotatedImage extends StatelessWidget {
  final Uint8List imageBytes;
  final List<Detection> detections;
  final ImageDimensions imageDimensions;
  final int highlightedIdx;
  final Size maxSize;
  final bool showLabels;
  final ValueChanged<int>? onTapDetection;

  const _AnnotatedImage({
    required this.imageBytes,
    required this.detections,
    required this.imageDimensions,
    required this.highlightedIdx,
    required this.maxSize,
    required this.showLabels,
    this.onTapDetection,
  });

  @override
  Widget build(BuildContext context) {
    final imgW = imageDimensions.width.toDouble();
    final imgH = imageDimensions.height.toDouble();
    if (imgW <= 0 || imgH <= 0) {
      return Image.memory(imageBytes, fit: BoxFit.contain);
    }

    final scaleX = maxSize.width / imgW;
    final scaleY = maxSize.height / imgH;
    final scale = math.min(scaleX, scaleY);
    final dw = imgW * scale;
    final dh = imgH * scale;

    return SizedBox(
      width: dw,
      height: dh,
      child: Stack(
        children: [
          // Base image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(imageBytes, fit: BoxFit.fill),
            ),
          ),
          // Annotation overlay (CustomPaint for crisp rendering)
          Positioned.fill(
            child: CustomPaint(
              painter: _AnnotationPainter(
                detections: detections,
                scale: scale,
                highlightedIdx: highlightedIdx,
                showLabels: showLabels,
              ),
            ),
          ),
          // Invisible hit-test boxes
          for (int i = 0; i < detections.length; i++)
            _hitBox(detections[i], i, scale),
        ],
      ),
    );
  }

  Widget _hitBox(Detection d, int idx, double scale) {
    return Positioned(
      left: d.boundingBox.x1 * scale,
      top: d.boundingBox.y1 * scale,
      width: (d.boundingBox.width * scale).clamp(10, double.infinity),
      height: (d.boundingBox.height * scale).clamp(10, double.infinity),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onTapDetection?.call(idx),
          behavior: HitTestBehavior.opaque,
        ),
      ),
    );
  }
}

// =============================================================================
// _AnnotationPainter — Pearl AI-style tooth contour tracing
//
// Instead of bounding boxes, generates anatomically-plausible organic tooth
// contour paths from the detection bounding boxes using cubic Bezier curves.
//
// Features:
//  • Condition-specific organic contour shapes (tooth, lesion, filling, etc.)
//  • Prominent semi-transparent polygon fills (Pearl AI style)
//  • Thick colored contour outlines scaled to image size
//  • Outer glow for a "lit-up" radiology highlight effect
//  • Minimal non-overlapping labels with leader lines
// =============================================================================

class _AnnotationPainter extends CustomPainter {
  final List<Detection> detections;
  final double scale;
  final int highlightedIdx;
  final bool showLabels;

  _AnnotationPainter({
    required this.detections,
    required this.scale,
    required this.highlightedIdx,
    required this.showLabels,
  });

  // Base stroke width scales with image. Looks thick & prominent.
  double get _baseStroke => (1.8 * math.sqrt(scale)).clamp(1.5, 4.0);

  @override
  void paint(Canvas canvas, Size size) {
    final labelRects = <Rect>[];
    final adaptiveFont = (10.0 * (scale / 2.0)).clamp(9.0, 13.0);

    // === PASS 1: draw all non-highlighted contours first ===
    for (int i = 0; i < detections.length; i++) {
      if (i == highlightedIdx) continue;
      _drawContour(
        canvas,
        size,
        detections[i],
        i,
        false,
        labelRects,
        adaptiveFont,
      );
    }
    // === PASS 2: draw highlighted on top so it's always prominent ===
    if (highlightedIdx >= 0 && highlightedIdx < detections.length) {
      _drawContour(
        canvas,
        size,
        detections[highlightedIdx],
        highlightedIdx,
        true,
        labelRects,
        adaptiveFont,
      );
    }
  }

  void _drawContour(
    Canvas canvas,
    Size size,
    Detection d,
    int idx,
    bool isHl,
    List<Rect> labelRects,
    double fontSize,
  ) {
    final c = _conditionColor(d.label);
    final box = Rect.fromLTRB(
      d.boundingBox.x1 * scale,
      d.boundingBox.y1 * scale,
      d.boundingBox.x2 * scale,
      d.boundingBox.y2 * scale,
    );

    // Generate organic contour path
    final path = _buildContourPath(box, d.label, idx);

    // ── 1. Outer glow (always, more prominent when highlighted) ──
    final glowPaint = Paint()
      ..color = c.withValues(alpha: isHl ? 0.45 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _baseStroke * (isHl ? 5.0 : 3.0)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _baseStroke * (isHl ? 3.5 : 2.0),
      );
    canvas.drawPath(path, glowPaint);

    // ── 2. Semi-transparent polygon fill ──
    final fillPaint = Paint()
      ..color = c.withValues(alpha: isHl ? 0.28 : 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // ── 3. Inner glow for highlighted ──
    if (isHl) {
      final innerGlow = Paint()
        ..color = c.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 6);
      canvas.drawPath(path, innerGlow);
    }

    // ── 4. Main contour outline — thick, prominent ──
    final strokePaint = Paint()
      ..color = c.withValues(alpha: isHl ? 1.0 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _baseStroke * (isHl ? 2.2 : 1.4)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // ── 5. Fine inner stroke for depth (Pearl AI double-line effect) ──
    final innerStroke = Paint()
      ..color = c.withValues(alpha: isHl ? 0.35 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _baseStroke * 0.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, innerStroke);

    // ── 6. Label ──
    if (showLabels) {
      _drawLabel(canvas, size, d, c, box, idx, isHl, labelRects, fontSize);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTOUR PATH BUILDER — condition-aware organic shapes
  // ═══════════════════════════════════════════════════════════════════════════

  Path _buildContourPath(Rect box, String label, int seed) {
    final l = label.toLowerCase();
    if (l.contains('caries') || l.contains('cavity')) {
      return _cariesContour(box, seed);
    }
    if (l.contains('impacted') || l.contains('missing')) {
      return _toothContour(box, seed);
    }
    if (l.contains('filling')) {
      return _fillingContour(box, seed);
    }
    if (l.contains('root canal') || l.contains('root_canal')) {
      return _rootCanalContour(box, seed);
    }
    if (l.contains('crown') || l.contains('bridge')) {
      return _crownContour(box, seed);
    }
    if (l.contains('periapical') || l.contains('abscess')) {
      return _lesionContour(box, seed);
    }
    if (l.contains('calculus') ||
        l.contains('tartar') ||
        l.contains('gingivitis')) {
      return _ridgeContour(box, seed);
    }
    // Default: organic tooth-like shape
    return _toothContour(box, seed);
  }

  // ─── Tooth contour: bell-curve crown with tapered root ────────────────
  //
  //        ╭──────╮        ← rounded crown top
  //       │        │       ← slightly wider body
  //       │        │
  //        ╲      ╱        ← taper to root
  //         ╲    ╱
  //          ╰──╯          ← narrower root tip
  //
  Path _toothContour(Rect box, int seed) {
    final cx = box.center.dx;
    final w = box.width;
    final h = box.height;
    // Deterministic variation based on seed
    final v = (seed * 0.173 - seed ~/ 3 * 0.5).abs() % 1.0;
    final crownW = w * (0.48 + v * 0.04); // half-width at crown
    final rootW = w * (0.18 + v * 0.06); // half-width at root

    final path = Path();
    // Start at top-left of crown
    path.moveTo(cx - crownW * 0.6, box.top + h * 0.08);

    // Crown top (rounded)
    path.cubicTo(
      cx - crownW * 0.3,
      box.top - h * 0.02,
      cx + crownW * 0.3,
      box.top - h * 0.02,
      cx + crownW * 0.6,
      box.top + h * 0.08,
    );

    // Right side — slight bulge then taper
    path.cubicTo(
      cx + crownW * 0.85,
      box.top + h * 0.18,
      cx + crownW * 0.95,
      box.top + h * 0.35,
      cx + crownW * 0.8,
      box.top + h * 0.52,
    );

    // Right taper to root
    path.cubicTo(
      cx + crownW * 0.55,
      box.top + h * 0.68,
      cx + rootW * 1.2,
      box.top + h * 0.82,
      cx + rootW * 0.5,
      box.bottom - h * 0.03,
    );

    // Root tip (rounded)
    path.cubicTo(
      cx + rootW * 0.1,
      box.bottom + h * 0.01,
      cx - rootW * 0.1,
      box.bottom + h * 0.01,
      cx - rootW * 0.5,
      box.bottom - h * 0.03,
    );

    // Left taper from root
    path.cubicTo(
      cx - rootW * 1.2,
      box.top + h * 0.82,
      cx - crownW * 0.55,
      box.top + h * 0.68,
      cx - crownW * 0.8,
      box.top + h * 0.52,
    );

    // Left side — back up to crown
    path.cubicTo(
      cx - crownW * 0.95,
      box.top + h * 0.35,
      cx - crownW * 0.85,
      box.top + h * 0.18,
      cx - crownW * 0.6,
      box.top + h * 0.08,
    );

    path.close();
    return path;
  }

  // ─── Caries contour: irregular organic blob (decay) ───────────────────
  Path _cariesContour(Rect box, int seed) {
    final cx = box.center.dx;
    final cy = box.center.dy;
    final rx = box.width * 0.48;
    final ry = box.height * 0.48;

    // Generate 8 radial control points with irregular offsets
    const nPoints = 8;
    final rng = math.Random(seed * 7 + 42);
    final points = <Offset>[];
    for (int i = 0; i < nPoints; i++) {
      final angle = (i / nPoints) * 2 * math.pi;
      final rFactor = 0.7 + rng.nextDouble() * 0.5;
      points.add(
        Offset(
          cx + rx * rFactor * math.cos(angle),
          cy + ry * rFactor * math.sin(angle),
        ),
      );
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < nPoints; i++) {
      final p0 = points[i];
      final p1 = points[(i + 1) % nPoints];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      // Pull control point towards center for organic bulge
      final cpx = midX + (cx - midX) * (rng.nextDouble() * 0.4 - 0.2);
      final cpy = midY + (cy - midY) * (rng.nextDouble() * 0.4 - 0.2);
      path.quadraticBezierTo(cpx, cpy, p1.dx, p1.dy);
    }
    path.close();
    return path;
  }

  // ─── Filling contour: smooth rounded capsule ─────────────────────────
  Path _fillingContour(Rect box, int seed) {
    final cx = box.center.dx;
    final cy = box.center.dy;
    final w = box.width;
    final h = box.height;
    final rx = w * 0.46;
    final ry = h * 0.46;

    // Superellipse-like shape (slightly rectangular organic feel)
    const nPoints = 12;
    final path = Path();
    for (int i = 0; i <= nPoints; i++) {
      final t = (i / nPoints) * 2 * math.pi;
      final cosT = math.cos(t);
      final sinT = math.sin(t);
      // Squircle formula: sign * |cos|^n creates rounded-rect organic shape
      final px = cx + rx * cosT.sign * math.pow(cosT.abs(), 0.7);
      final py = cy + ry * sinT.sign * math.pow(sinT.abs(), 0.7);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    // Smooth it with a second pass can be tricky in Path, so let's use
    // the lineTo chain which is already smooth enough at 12 points
    return path;
  }

  // ─── Root canal contour: elongated channel shape ──────────────────────
  Path _rootCanalContour(Rect box, int seed) {
    final cx = box.center.dx;
    final w = box.width;
    final h = box.height;
    final chanW = w * 0.35;

    final path = Path();
    // Start top-left
    path.moveTo(cx - chanW, box.top + h * 0.05);
    // Top cap (rounded)
    path.cubicTo(
      cx - chanW * 0.3,
      box.top - h * 0.03,
      cx + chanW * 0.3,
      box.top - h * 0.03,
      cx + chanW,
      box.top + h * 0.05,
    );
    // Right side — slight organic waviness
    path.cubicTo(
      cx + chanW * 1.15,
      box.top + h * 0.25,
      cx + chanW * 0.85,
      box.top + h * 0.50,
      cx + chanW * 0.95,
      box.top + h * 0.70,
    );
    // Taper to root tip
    path.cubicTo(
      cx + chanW * 0.7,
      box.top + h * 0.85,
      cx + chanW * 0.3,
      box.bottom + h * 0.01,
      cx,
      box.bottom,
    );
    // Root tip left
    path.cubicTo(
      cx - chanW * 0.3,
      box.bottom + h * 0.01,
      cx - chanW * 0.7,
      box.top + h * 0.85,
      cx - chanW * 0.95,
      box.top + h * 0.70,
    );
    // Left side back up
    path.cubicTo(
      cx - chanW * 0.85,
      box.top + h * 0.50,
      cx - chanW * 1.15,
      box.top + h * 0.25,
      cx - chanW,
      box.top + h * 0.05,
    );
    path.close();
    return path;
  }

  // ─── Crown contour: dome/cap shape over the upper region ──────────────
  Path _crownContour(Rect box, int seed) {
    final cx = box.center.dx;
    final w = box.width;
    final h = box.height;
    final capW = w * 0.5;

    final path = Path();
    // Flat bottom
    path.moveTo(cx - capW, box.bottom - h * 0.08);
    // Bottom edge (slight curve)
    path.cubicTo(
      cx - capW * 0.5,
      box.bottom + h * 0.02,
      cx + capW * 0.5,
      box.bottom + h * 0.02,
      cx + capW,
      box.bottom - h * 0.08,
    );
    // Right side up
    path.cubicTo(
      cx + capW * 1.1,
      box.top + h * 0.55,
      cx + capW * 0.95,
      box.top + h * 0.25,
      cx + capW * 0.5,
      box.top + h * 0.05,
    );
    // Dome top
    path.cubicTo(
      cx + capW * 0.2,
      box.top - h * 0.02,
      cx - capW * 0.2,
      box.top - h * 0.02,
      cx - capW * 0.5,
      box.top + h * 0.05,
    );
    // Left side down
    path.cubicTo(
      cx - capW * 0.95,
      box.top + h * 0.25,
      cx - capW * 1.1,
      box.top + h * 0.55,
      cx - capW,
      box.bottom - h * 0.08,
    );
    path.close();
    return path;
  }

  // ─── Lesion contour: rounded oval/blob ────────────────────────────────
  Path _lesionContour(Rect box, int seed) {
    final cx = box.center.dx;
    final cy = box.center.dy;
    final rx = box.width * 0.47;
    final ry = box.height * 0.47;
    final rng = math.Random(seed * 13 + 7);

    const nPoints = 10;
    final points = <Offset>[];
    for (int i = 0; i < nPoints; i++) {
      final angle = (i / nPoints) * 2 * math.pi;
      final rFactor = 0.85 + rng.nextDouble() * 0.3;
      points.add(
        Offset(
          cx + rx * rFactor * math.cos(angle),
          cy + ry * rFactor * math.sin(angle),
        ),
      );
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < nPoints; i++) {
      final p1 = points[(i + 1) % nPoints];
      final p0 = points[i];
      path.quadraticBezierTo(
        (p0.dx + p1.dx) / 2 + (cx - (p0.dx + p1.dx) / 2) * 0.15,
        (p0.dy + p1.dy) / 2 + (cy - (p0.dy + p1.dy) / 2) * 0.15,
        p1.dx,
        p1.dy,
      );
    }
    path.close();
    return path;
  }

  // ─── Ridge contour (calculus/tartar): crescent along edge ─────────────
  Path _ridgeContour(Rect box, int seed) {
    final cx = box.center.dx;
    final w = box.width;
    final h = box.height;
    final isWide = w > h;

    final path = Path();
    if (isWide) {
      // Horizontal crescent along top/bottom
      path.moveTo(box.left + w * 0.05, box.center.dy);
      path.cubicTo(
        box.left + w * 0.2,
        box.top - h * 0.1,
        box.right - w * 0.2,
        box.top - h * 0.1,
        box.right - w * 0.05,
        box.center.dy,
      );
      path.cubicTo(
        box.right - w * 0.2,
        box.bottom + h * 0.05,
        box.left + w * 0.2,
        box.bottom + h * 0.05,
        box.left + w * 0.05,
        box.center.dy,
      );
    } else {
      // Vertical crescent along left/right
      path.moveTo(cx, box.top + h * 0.05);
      path.cubicTo(
        box.right + w * 0.1,
        box.top + h * 0.2,
        box.right + w * 0.1,
        box.bottom - h * 0.2,
        cx,
        box.bottom - h * 0.05,
      );
      path.cubicTo(
        box.left - w * 0.05,
        box.bottom - h * 0.2,
        box.left - w * 0.05,
        box.top + h * 0.2,
        cx,
        box.top + h * 0.05,
      );
    }
    path.close();
    return path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LABEL RENDERING — minimal Pearl AI-style tags
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawLabel(
    Canvas canvas,
    Size size,
    Detection d,
    Color c,
    Rect boxRect,
    int idx,
    bool isHl,
    List<Rect> placed,
    double fontSize,
  ) {
    final labelTp = TextPainter(
      text: TextSpan(
        text: d.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.35);

    final confTp = TextPainter(
      text: TextSpan(
        text: d.confidencePercent,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: fontSize - 1,
          fontWeight: FontWeight.w700,
          fontFamily: _T.monoFont,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const padH = 6.0;
    const padV = 3.0;
    const gap = 5.0;
    final totalW = padH + labelTp.width + gap + confTp.width + padH;
    final totalH = padV + math.max(labelTp.height, confTp.height) + padV;

    // Try positions: above, below, right, inside
    final candidates = <Offset>[
      Offset(boxRect.left, boxRect.top - totalH - 4),
      Offset(boxRect.left, boxRect.bottom + 4),
      Offset(boxRect.right + 4, boxRect.top),
      Offset(boxRect.left + 4, boxRect.top + 4),
    ];

    Offset pos = candidates[0];
    bool found = false;
    for (final cand in candidates) {
      final clamped = Rect.fromLTWH(
        cand.dx.clamp(
          1.0,
          (size.width - totalW - 1).clamp(1.0, double.infinity),
        ),
        cand.dy.clamp(
          1.0,
          (size.height - totalH - 1).clamp(1.0, double.infinity),
        ),
        totalW,
        totalH,
      );
      if (!placed.any((p) => p.overlaps(clamped.inflate(1)))) {
        pos = clamped.topLeft;
        placed.add(clamped);
        found = true;
        break;
      }
    }
    if (!found) {
      final shifted = Rect.fromLTWH(
        candidates[0].dx.clamp(
          1.0,
          (size.width - totalW - 1).clamp(1.0, double.infinity),
        ),
        (boxRect.top - totalH - 4 + placed.length * (totalH + 3)).clamp(
          1.0,
          size.height - totalH - 1,
        ),
        totalW,
        totalH,
      );
      pos = shifted.topLeft;
      placed.add(shifted);
    }

    final labelRect = Rect.fromLTWH(pos.dx, pos.dy, totalW, totalH);
    final rrect = RRect.fromRectAndRadius(labelRect, const Radius.circular(3));

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Background
    canvas.drawRRect(rrect, Paint()..color = const Color(0xE8141820));

    // Left accent bar
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        labelRect.left,
        labelRect.top,
        labelRect.left + 3,
        labelRect.bottom,
        topLeft: const Radius.circular(3),
        bottomLeft: const Radius.circular(3),
      ),
      Paint()..color = c,
    );

    // Texts
    final textY = pos.dy + padV;
    labelTp.paint(canvas, Offset(pos.dx + padH + 2, textY));
    confTp.paint(
      canvas,
      Offset(pos.dx + padH + 2 + labelTp.width + gap, textY),
    );

    // Leader line
    if (!boxRect.contains(labelRect.center)) {
      final startPt = Offset(
        labelRect.center.dx.clamp(boxRect.left, boxRect.right),
        labelRect.bottom > boxRect.top
            ? (labelRect.top < boxRect.top ? labelRect.bottom : labelRect.top)
            : labelRect.bottom,
      );
      final endPt = Offset(
        boxRect.center.dx.clamp(boxRect.left + 3, boxRect.right - 3),
        startPt.dy < boxRect.top ? boxRect.top : boxRect.bottom,
      );
      canvas.drawLine(
        startPt,
        endPt,
        Paint()
          ..color = c.withValues(alpha: 0.35)
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter old) =>
      old.highlightedIdx != highlightedIdx ||
      old.showLabels != showLabels ||
      old.scale != scale;
}

// =============================================================================
// _FullScreenViewer — DICOM-style modal (ESC to close, pan + zoom)
//
// Dark theme viewer with:
//  • InteractiveViewer for pan/zoom
//  • Same CustomPainter annotations (crisp at all zoom levels)
//  • Toggleable side panel with findings
//  • Keyboard shortcut: ESC to close
// =============================================================================

class _FullScreenViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final DetectionResponse result;
  const _FullScreenViewer({required this.imageBytes, required this.result});
  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  final _tx = TransformationController();
  int _hlIdx = -1;
  bool _showPanel = true;
  bool _showLabels = true;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();
  }

  @override
  void dispose() {
    _tx.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 700;
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: _imageArea()),
                          if (_showPanel) ...[
                            Container(width: 1, color: _T.panelBorder),
                            SizedBox(width: 340, child: _sidePanel()),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _imageArea()),
                          if (_showPanel) ...[
                            Container(height: 1, color: _T.panelBorder),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.32,
                              child: _sidePanel(),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: _T.panelSurface,
        border: Border(bottom: BorderSide(color: _T.panelBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: _T.textMuted),
            iconSize: 20,
            tooltip: 'Close (ESC)',
            style: IconButton.styleFrom(padding: const EdgeInsets.all(6)),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.medical_information_outlined,
            color: _T.accent,
            size: 16,
          ),
          const SizedBox(width: 6),
          const Text(
            'Diagnostic Viewer',
            style: TextStyle(
              color: _T.textBright,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          _modalBtn(
            icon: _showLabels ? Icons.label : Icons.label_off_outlined,
            tooltip: 'Toggle labels',
            onTap: () => setState(() => _showLabels = !_showLabels),
          ),
          _modalBtn(
            icon: Icons.view_sidebar,
            tooltip: _showPanel ? 'Hide panel' : 'Show panel',
            onTap: () => setState(() => _showPanel = !_showPanel),
            active: _showPanel,
          ),
          _modalBtn(
            icon: Icons.fit_screen_outlined,
            tooltip: 'Reset zoom',
            onTap: () => _tx.value = Matrix4.identity(),
          ),
        ],
      ),
    );
  }

  Widget _modalBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? _T.accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: active ? _T.accent : _T.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageArea() {
    final result = widget.result;
    final imgW = result.imageDimensions.width.toDouble();
    final imgH = result.imageDimensions.height.toDouble();

    return InteractiveViewer(
      transformationController: _tx,
      minScale: 0.3,
      maxScale: 8.0,
      child: Center(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            if (imgW <= 0 || imgH <= 0) {
              return Image.memory(widget.imageBytes, fit: BoxFit.contain);
            }
            final scaleX = constraints.maxWidth / imgW;
            final scaleY = constraints.maxHeight / imgH;
            final scale = math.min(scaleX, scaleY) * 0.94;
            final dw = imgW * scale;
            final dh = imgH * scale;

            return SizedBox(
              width: dw,
              height: dh,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(widget.imageBytes, fit: BoxFit.fill),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AnnotationPainter(
                        detections: result.detections,
                        scale: scale,
                        highlightedIdx: _hlIdx,
                        showLabels: _showLabels,
                      ),
                    ),
                  ),
                  for (int i = 0; i < result.detections.length; i++)
                    _hitBox(result.detections[i], i, scale),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hitBox(Detection d, int idx, double scale) {
    return Positioned(
      left: d.boundingBox.x1 * scale,
      top: d.boundingBox.y1 * scale,
      width: (d.boundingBox.width * scale).clamp(10, double.infinity),
      height: (d.boundingBox.height * scale).clamp(10, double.infinity),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _hlIdx = _hlIdx == idx ? -1 : idx),
          behavior: HitTestBehavior.opaque,
        ),
      ),
    );
  }

  Widget _sidePanel() {
    final result = widget.result;
    return Container(
      color: _T.panelBg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.panelBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: _T.accent,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Findings Report',
                    style: TextStyle(
                      color: _T.textBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _T.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _T.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${result.detectionCount} found',
                    style: const TextStyle(
                      color: _T.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: _T.monoFont,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Summary
          if (result.classSummary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.panelBorder)),
              ),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: result.classSummary.entries.map((e) {
                  final c = _conditionColor(e.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: c.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                        color: c.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // List
          Expanded(
            child: result.detections.isEmpty
                ? const Center(
                    child: Text(
                      'No findings',
                      style: TextStyle(color: _T.textMuted, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: result.detections.length,
                    itemBuilder: (_, i) {
                      final d = result.detections[i];
                      final isHl = _hlIdx == i;
                      final c = _conditionColor(d.label);
                      return Material(
                        color: isHl
                            ? c.withValues(alpha: 0.08)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _hlIdx = _hlIdx == i ? -1 : i),
                          hoverColor: c.withValues(alpha: 0.05),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: isHl ? c : Colors.transparent,
                                  width: 3,
                                ),
                                bottom: const BorderSide(
                                  color: _T.panelBorder,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.label,
                                        style: const TextStyle(
                                          color: _T.textBright,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // Confidence bar
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: d.confidence.clamp(0, 1),
                                                minHeight: 3,
                                                backgroundColor: _T.panelBorder,
                                                color: c,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            d.confidencePercent,
                                            style: TextStyle(
                                              color: c,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: _T.monoFont,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '(${d.boundingBox.x1.toStringAsFixed(0)}, ${d.boundingBox.y1.toStringAsFixed(0)}) → (${d.boundingBox.x2.toStringAsFixed(0)}, ${d.boundingBox.y2.toStringAsFixed(0)})',
                                        style: const TextStyle(
                                          color: _T.textDim,
                                          fontSize: 9,
                                          fontFamily: _T.monoFont,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
