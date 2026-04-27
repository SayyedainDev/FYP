import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/case_model.dart';
import '../models/prescription_model.dart';
import '../models/patient.dart';
import '../repositories/case_repository.dart';

part 'scan_history_provider.freezed.dart';
part 'scan_history_provider.g.dart';

@riverpod
CaseRepository caseRepository(CaseRepositoryRef ref) {
  return CaseRepository();
}

// ── Filter state ──────────────────────────────────────────
@riverpod
class ScanHistoryFilter extends _$ScanHistoryFilter {
  @override
  ScanFilterState build() => const ScanFilterState();

  void setPatient(String? patientId) =>
      state = state.copyWith(patientId: patientId);
  void setDateRange(DateTimeRange? range) =>
      state = state.copyWith(dateRange: range);
  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);
  void setStatus(String? status) =>
      state = state.copyWith(statusFilter: status);
  void reset() => state = const ScanFilterState();
}

@freezed
abstract class ScanFilterState with _$ScanFilterState {
  const factory ScanFilterState({
    String? patientId,
    DateTimeRange? dateRange,
    @Default('') String searchQuery,
    String? statusFilter, // null = All
  }) = _ScanFilterState;
}

// ── Cases stream (Firestore realtime) ────────────────────
@riverpod
Stream<List<CaseModel>> casesStream(CasesStreamRef ref) {
  final filter = ref.watch(scanHistoryFilterProvider);
  return ref.watch(caseRepositoryProvider).watchCases(
        patientId: filter.patientId,
        startDate: filter.dateRange?.start,
        endDate: filter.dateRange?.end,
      );
}

// ── Filtered + searched list (client-side for instant search) ──
@riverpod
List<CaseModel> filteredCases(FilteredCasesRef ref) {
  final casesAsync = ref.watch(casesStreamProvider);
  final filter = ref.watch(scanHistoryFilterProvider);

  return casesAsync.when(
    data: (cases) {
      var result = cases;

      // Client-side search (patientName, details)
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        result = result.where((c) =>
            c.patientName.toLowerCase().contains(q) ||
            c.analysisResults.details.toLowerCase().contains(q)).toList();
      }

      // Client-side status filter
      if (filter.statusFilter != null) {
        result = result.where((c) => c.displayStatus == filter.statusFilter).toList();
      }

      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
}

// ── Selected case ID ─────────────────────────────────────
@riverpod
class SelectedCaseId extends _$SelectedCaseId {
  @override
  String? build() => null;
  void select(String id) => state = id;
  void clear() => state = null;
}

// ── Full case detail (case + prescription joined) ────────
@riverpod
Future<({CaseModel caseModel, PrescriptionModel? prescription})>
caseDetail(CaseDetailRef ref, String caseId) async {
  final repo = ref.watch(caseRepositoryProvider);
  final caseModel = await repo.getCaseById(caseId);
  if (caseModel == null) throw Exception('Case not found');
  final prescription = await repo.getPrescriptionForCase(caseId);
  return (caseModel: caseModel, prescription: prescription);
}

// ── Patients for filter dropdown ─────────────────────────
@riverpod
Stream<List<Patient>> patientsStream(PatientsStreamRef ref) =>
    ref.watch(caseRepositoryProvider).watchPatients();
