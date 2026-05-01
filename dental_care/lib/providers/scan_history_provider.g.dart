// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$caseRepositoryHash() => r'6c50a1699feab3f53112fab52cd86234e473b8a8';

/// See also [caseRepository].
@ProviderFor(caseRepository)
final caseRepositoryProvider = AutoDisposeProvider<CaseRepository>.internal(
  caseRepository,
  name: r'caseRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$caseRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CaseRepositoryRef = AutoDisposeProviderRef<CaseRepository>;
String _$casesStreamHash() => r'9cf0af08a481186f3f667968a02a1526939c39fb';

/// See also [casesStream].
@ProviderFor(casesStream)
final casesStreamProvider = AutoDisposeStreamProvider<List<CaseModel>>.internal(
  casesStream,
  name: r'casesStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$casesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CasesStreamRef = AutoDisposeStreamProviderRef<List<CaseModel>>;
String _$filteredCasesHash() => r'7cd462a7c7767b99d65b43a475d4f16e156fc3bb';

/// See also [filteredCases].
@ProviderFor(filteredCases)
final filteredCasesProvider = AutoDisposeProvider<List<CaseModel>>.internal(
  filteredCases,
  name: r'filteredCasesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredCasesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredCasesRef = AutoDisposeProviderRef<List<CaseModel>>;
String _$caseDetailHash() => r'a103fdeed44ff95a226d4db901de0a0e470434fb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [caseDetail].
@ProviderFor(caseDetail)
const caseDetailProvider = CaseDetailFamily();

/// See also [caseDetail].
class CaseDetailFamily extends Family<
    AsyncValue<({CaseModel caseModel, PrescriptionModel? prescription})>> {
  /// See also [caseDetail].
  const CaseDetailFamily();

  /// See also [caseDetail].
  CaseDetailProvider call(
    String caseId,
  ) {
    return CaseDetailProvider(
      caseId,
    );
  }

  @override
  CaseDetailProvider getProviderOverride(
    covariant CaseDetailProvider provider,
  ) {
    return call(
      provider.caseId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'caseDetailProvider';
}

/// See also [caseDetail].
class CaseDetailProvider extends AutoDisposeFutureProvider<
    ({CaseModel caseModel, PrescriptionModel? prescription})> {
  /// See also [caseDetail].
  CaseDetailProvider(
    String caseId,
  ) : this._internal(
          (ref) => caseDetail(
            ref as CaseDetailRef,
            caseId,
          ),
          from: caseDetailProvider,
          name: r'caseDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$caseDetailHash,
          dependencies: CaseDetailFamily._dependencies,
          allTransitiveDependencies:
              CaseDetailFamily._allTransitiveDependencies,
          caseId: caseId,
        );

  CaseDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.caseId,
  }) : super.internal();

  final String caseId;

  @override
  Override overrideWith(
    FutureOr<({CaseModel caseModel, PrescriptionModel? prescription})> Function(
            CaseDetailRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CaseDetailProvider._internal(
        (ref) => create(ref as CaseDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        caseId: caseId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<
          ({CaseModel caseModel, PrescriptionModel? prescription})>
      createElement() {
    return _CaseDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CaseDetailProvider && other.caseId == caseId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, caseId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CaseDetailRef on AutoDisposeFutureProviderRef<
    ({CaseModel caseModel, PrescriptionModel? prescription})> {
  /// The parameter `caseId` of this provider.
  String get caseId;
}

class _CaseDetailProviderElement extends AutoDisposeFutureProviderElement<
        ({CaseModel caseModel, PrescriptionModel? prescription})>
    with CaseDetailRef {
  _CaseDetailProviderElement(super.provider);

  @override
  String get caseId => (origin as CaseDetailProvider).caseId;
}

String _$patientsStreamHash() => r'0fbea4f8bd625f48568ca85c961d397dfe9339c3';

/// See also [patientsStream].
@ProviderFor(patientsStream)
final patientsStreamProvider =
    AutoDisposeStreamProvider<List<Patient>>.internal(
  patientsStream,
  name: r'patientsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$patientsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PatientsStreamRef = AutoDisposeStreamProviderRef<List<Patient>>;
String _$scanHistoryFilterHash() => r'efe6cff2f2145f831dca003b87578e9edba78171';

/// See also [ScanHistoryFilter].
@ProviderFor(ScanHistoryFilter)
final scanHistoryFilterProvider =
    AutoDisposeNotifierProvider<ScanHistoryFilter, ScanFilterState>.internal(
  ScanHistoryFilter.new,
  name: r'scanHistoryFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scanHistoryFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScanHistoryFilter = AutoDisposeNotifier<ScanFilterState>;
String _$selectedCaseIdHash() => r'84bbde7570795622c81f2e569b61a9930bbc7195';

/// See also [SelectedCaseId].
@ProviderFor(SelectedCaseId)
final selectedCaseIdProvider =
    AutoDisposeNotifierProvider<SelectedCaseId, String?>.internal(
  SelectedCaseId.new,
  name: r'selectedCaseIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCaseIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCaseId = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
