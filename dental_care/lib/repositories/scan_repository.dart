import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan_model.dart';
import 'package:flutter/foundation.dart';

class ScanRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all scans with their findings and prescription (left join)
  Future<List<ScanModel>> getScans({
    String? patientId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    var query = _client
        .from('scans')
        .select('*, scan_findings(*), prescriptions(*)');

    if (patientId != null) query = query.eq('patient_id', patientId);
    if (status != null) query = query.eq('status', status);
    if (startDate != null) query = query.gte('scan_date', startDate.toIso8601String());
    if (endDate != null) query = query.lte('scan_date', endDate.toIso8601String());
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('patient_name', '%$searchQuery%');
    }

    final data = await query.order('scan_date', ascending: false);
    return data.map((e) => ScanModel.fromJson(e)).toList();
  }

  Future<ScanModel?> getScanById(String scanId) async {
    final data = await _client
        .from('scans')
        .select('*, scan_findings(*), prescriptions(*)')
        .eq('id', scanId)
        .maybeSingle();

    if (data == null) return null;
    return ScanModel.fromJson(data);
  }

  // Upload image to Supabase
  Future<String> uploadImage(String scanId, Uint8List imageBytes) async {
    final storagePath = 'cases/$scanId/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('Image').uploadBinary(
      storagePath,
      imageBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );
    return _client.storage.from('Image').getPublicUrl(storagePath);
  }

  // Insert a base scan and upload the image url if needed
  Future<String> saveScan({
    required String patientId,
    required String patientName,
    required String scanType,
    String? imageUrl,
  }) async {
    final result = await _client.from('scans').insert({
      'patient_id': patientId,
      'patient_name': patientName,
      'scan_type': scanType,
      'image_url': imageUrl,
      'status': 'uploaded',
      'finding_count': 0,
    }).select().single();

    return result['id'] as String;
  }

  Future<void> saveFindings(String scanId, List<ScanFinding> findings) async {
    if (findings.isEmpty) {
      // Just update status to analyzed
      await _client.from('scans').update({
        'status': 'analyzed',
        'finding_count': 0
      }).eq('id', scanId);
      return;
    }

    final insertData = findings.map((f) => f.toJson()).toList();
    await _client.from('scan_findings').insert(insertData);

    await _client.from('scans').update({
      'status': 'analyzed',
      'finding_count': findings.length
    }).eq('id', scanId);
  }

  Future<void> savePrescription(PrescriptionModel rx) async {
    await _client.from('prescriptions').insert(rx.toJson());
    await _client.from('scans').update({'status': 'prescribed'}).eq('id', rx.scanId);
  }

  // Realtime listener
  RealtimeChannel watchScans(void Function(ScanModel) onUpdate) {
    return _client
        .channel('scans')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scans',
          callback: (payload) {
            // Note: Since this payload only contains the scans table record and not the relations,
            // we should refetch the whole scan record to get the joined findings and prescriptions.
            if (payload.eventType == PostgresChangeEvent.insert || payload.eventType == PostgresChangeEvent.update) {
              final newId = payload.newRecord['id'];
              getScanById(newId as String).then((fullScan) {
                if (fullScan != null) onUpdate(fullScan);
              }).catchError((e) {
                debugPrint('Error fetching updated scan details: $e');
              });
            }
          },
        )
        .subscribe();
  }
}
