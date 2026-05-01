import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientSelectorWidget extends StatefulWidget {
  final Function(String id, String name) onPatientSelected;
  final VoidCallback onPatientCleared;

  const PatientSelectorWidget({
    super.key,
    required this.onPatientSelected,
    required this.onPatientCleared,
  });

  @override
  State<PatientSelectorWidget> createState() => _PatientSelectorWidgetState();
}

class _PatientSelectorWidgetState extends State<PatientSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _errorMsg;
  Map<String, dynamic>? _selectedPatient;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('dentistUid', isEqualTo: uid)
          .get();

      final patients = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          // Handle potential missing fields from older records
          'name': data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'last_visit_date': data['last_visit_date'] ?? (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allPatients = patients;
          _results = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Failed to load patients: $e';
        });
      }
    }
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() => _results = _allPatients);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _results = _allPatients.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final phone = (p['phone'] ?? '').toString().toLowerCase();
        final id = p['id'].toString().toLowerCase();
        return name.contains(lowerQuery) || phone.contains(lowerQuery) || id.contains(lowerQuery);
      }).toList();
    });
  }

  Map<String, int> _buildNameCountMap(List<Map<String, dynamic>> patients) {
    final counts = <String, int>{};
    for (final p in patients) {
      final name = (p['name'] ?? '').toString().trim().toLowerCase();
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 6) return phone ?? '—';
    final start = phone.substring(0, 6);
    final end = phone.substring(phone.length - 4);
    return '$start···$end';
  }

  List<Color> _avatarColors(String patientId) {
    const palette = [
      [Color(0xFFDBEAFE), Color(0xFF1D4ED8)], // blue
      [Color(0xFFCCFBF1), Color(0xFF0F766E)], // teal
      [Color(0xFFEDE9FE), Color(0xFF6D28D9)], // purple
      [Color(0xFFFEF3C7), Color(0xFF92400E)], // amber
      [Color(0xFFFCE7F3), Color(0xFF9D174D)], // pink
    ];
    final index = patientId.hashCode.abs() % palette.length;
    return palette[index];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'No visits';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;

    if (_selectedPatient != null) {
      // The old simple "Selected" bubble
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF3B82F6), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedPatient!['name'] ?? 'Unknown Patient',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _selectedPatient = null);
                _searchController.clear();
                _search('');
                widget.onPatientCleared();
              },
              child: const Icon(Icons.close, size: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final counts = _buildNameCountMap(_results);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Simple search box
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search patient name...',
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
            suffixIcon: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
          onChanged: _search,
        ),
        
        // Error display
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              ],
            ),
          ),
          
        // Enhanced Results List directly beneath
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: borderColor.withValues(alpha: 0.5)),
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final p = _results[i];
                final name = (p['name'] ?? '').toString();
                final duplicateCount = counts[name.trim().toLowerCase()] ?? 0;
                final colors = _avatarColors(p['id'].toString());
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPatient = p;
                      _results = [];
                    });
                    widget.onPatientSelected(p['id'].toString(), p['name'].toString());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: colors[0], shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(_initials(name), style: TextStyle(color: colors[1], fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        
                        // Text info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  if (duplicateCount > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF9C3),
                                        border: Border.all(color: const Color(0xFFFDE68A), width: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$duplicateCount matches',
                                        style: const TextStyle(color: Color(0xFF713F12), fontSize: 9, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(p['id']?.toString() ?? '', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                                  const Text(' · ', style: TextStyle(color: Colors.grey)),
                                  Text('${p['gender'] ?? '?'} · ${p['age'] ?? '?'} yrs', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  const Text(' · ', style: TextStyle(color: Colors.grey)),
                                  Text(_maskPhone(p['phone']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Last visit
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatDate(p['last_visit_date']), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            const Text('Last visit', style: TextStyle(color: Colors.grey, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }
}
