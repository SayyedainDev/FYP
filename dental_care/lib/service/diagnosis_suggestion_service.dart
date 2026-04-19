import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SuggestionItem {
  final String diagnosis;
  final List<String> treatments;
  final List<Map<String, String>> medications;

  SuggestionItem({
    required this.diagnosis,
    required this.treatments,
    required this.medications,
  });

  factory SuggestionItem.fromJson(Map<String, dynamic> j) => SuggestionItem(
        diagnosis: j['diagnosis'] as String,
        treatments: (j['treatments'] as List<dynamic>).cast<String>(),
        medications: (j['medications'] as List<dynamic>)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
      );
}

class DiagnosisSuggestionService {
  static DiagnosisSuggestionService? _instance;
  List<SuggestionItem> _items = [];
  bool _loaded = false;

  DiagnosisSuggestionService._();

  static DiagnosisSuggestionService get instance {
    _instance ??= DiagnosisSuggestionService._();
    return _instance!;
  }

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle
        .loadString('assets/data/dental_suggestions.json')
        .catchError((_) => '[]');
    final list = jsonDecode(raw) as List<dynamic>;
    _items = list.map((e) => SuggestionItem.fromJson(e)).toList();
    _loaded = true;
  }

  /// Simple case-insensitive contains search on diagnosis and treatments
  Future<List<SuggestionItem>> search(String query) async {
    if (!_loaded) await load();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return _items.where((it) {
      final diag = it.diagnosis.toLowerCase();
      if (diag.contains(q)) return true;
      for (final t in it.treatments) {
        if (t.toLowerCase().contains(q)) return true;
      }
      for (final m in it.medications) {
        if (m['name']?.toLowerCase().contains(q) ?? false) return true;
      }
      return false;
    }).toList();
  }
}
