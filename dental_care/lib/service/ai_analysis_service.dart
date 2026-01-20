import 'dart:typed_data';

/// AI-ready analysis service abstraction.
/// Replace [DummyAiAnalysisService] with a real backend client later.
abstract class AiAnalysisService {
  Future<Map<String, dynamic>> analyze({
    required List<Uint8List> imageBytes,
    String? toothNumbers,
    String? caseTitle,
    Map<String, dynamic>? extra,
  });
}

class DummyAiAnalysisService implements AiAnalysisService {
  @override
  Future<Map<String, dynamic>> analyze({
    required List<Uint8List> imageBytes,
    String? toothNumbers,
    String? caseTitle,
    Map<String, dynamic>? extra,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'status': 'Analysis Complete',
      'confidence': 0.92,
      'riskLabel': 'Potential Lesion Detected',
      'verdictNotes': [
        'Potential Type II carious lesion detected on highlighted area.',
        if (toothNumbers != null && toothNumbers.isNotEmpty)
          'Teeth involved (FDI): $toothNumbers',
        'Recommend intraoral radiograph to confirm depth.',
      ],
      'annotations': [
        {'type': 'box', 'rect': [0.45, 0.35, 0.65, 0.55]},
        {'type': 'circle', 'center': [0.7, 0.65], 'radius': 0.05},
      ],
      'analyzedAt': DateTime.now().toIso8601String(),
    };
  }
}
