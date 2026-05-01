// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_history_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanFilterState {
  String? get patientId;
  DateTimeRange? get dateRange;
  String get searchQuery;
  String? get statusFilter;

  /// Create a copy of ScanFilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScanFilterStateCopyWith<ScanFilterState> get copyWith =>
      _$ScanFilterStateCopyWithImpl<ScanFilterState>(
          this as ScanFilterState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScanFilterState &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.statusFilter, statusFilter) ||
                other.statusFilter == statusFilter));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, patientId, dateRange, searchQuery, statusFilter);

  @override
  String toString() {
    return 'ScanFilterState(patientId: $patientId, dateRange: $dateRange, searchQuery: $searchQuery, statusFilter: $statusFilter)';
  }
}

/// @nodoc
abstract mixin class $ScanFilterStateCopyWith<$Res> {
  factory $ScanFilterStateCopyWith(
          ScanFilterState value, $Res Function(ScanFilterState) _then) =
      _$ScanFilterStateCopyWithImpl;
  @useResult
  $Res call(
      {String? patientId,
      DateTimeRange? dateRange,
      String searchQuery,
      String? statusFilter});
}

/// @nodoc
class _$ScanFilterStateCopyWithImpl<$Res>
    implements $ScanFilterStateCopyWith<$Res> {
  _$ScanFilterStateCopyWithImpl(this._self, this._then);

  final ScanFilterState _self;
  final $Res Function(ScanFilterState) _then;

  /// Create a copy of ScanFilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? patientId = freezed,
    Object? dateRange = freezed,
    Object? searchQuery = null,
    Object? statusFilter = freezed,
  }) {
    return _then(_self.copyWith(
      patientId: freezed == patientId
          ? _self.patientId
          : patientId // ignore: cast_nullable_to_non_nullable
              as String?,
      dateRange: freezed == dateRange
          ? _self.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      statusFilter: freezed == statusFilter
          ? _self.statusFilter
          : statusFilter // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ScanFilterState].
extension ScanFilterStatePatterns on ScanFilterState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ScanFilterState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScanFilterState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ScanFilterState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScanFilterState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ScanFilterState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScanFilterState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String? patientId, DateTimeRange? dateRange,
            String searchQuery, String? statusFilter)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScanFilterState() when $default != null:
        return $default(_that.patientId, _that.dateRange, _that.searchQuery,
            _that.statusFilter);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String? patientId, DateTimeRange? dateRange,
            String searchQuery, String? statusFilter)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScanFilterState():
        return $default(_that.patientId, _that.dateRange, _that.searchQuery,
            _that.statusFilter);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String? patientId, DateTimeRange? dateRange,
            String searchQuery, String? statusFilter)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScanFilterState() when $default != null:
        return $default(_that.patientId, _that.dateRange, _that.searchQuery,
            _that.statusFilter);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ScanFilterState implements ScanFilterState {
  const _ScanFilterState(
      {this.patientId,
      this.dateRange,
      this.searchQuery = '',
      this.statusFilter});

  @override
  final String? patientId;
  @override
  final DateTimeRange? dateRange;
  @override
  @JsonKey()
  final String searchQuery;
  @override
  final String? statusFilter;

  /// Create a copy of ScanFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScanFilterStateCopyWith<_ScanFilterState> get copyWith =>
      __$ScanFilterStateCopyWithImpl<_ScanFilterState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScanFilterState &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.statusFilter, statusFilter) ||
                other.statusFilter == statusFilter));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, patientId, dateRange, searchQuery, statusFilter);

  @override
  String toString() {
    return 'ScanFilterState(patientId: $patientId, dateRange: $dateRange, searchQuery: $searchQuery, statusFilter: $statusFilter)';
  }
}

/// @nodoc
abstract mixin class _$ScanFilterStateCopyWith<$Res>
    implements $ScanFilterStateCopyWith<$Res> {
  factory _$ScanFilterStateCopyWith(
          _ScanFilterState value, $Res Function(_ScanFilterState) _then) =
      __$ScanFilterStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? patientId,
      DateTimeRange? dateRange,
      String searchQuery,
      String? statusFilter});
}

/// @nodoc
class __$ScanFilterStateCopyWithImpl<$Res>
    implements _$ScanFilterStateCopyWith<$Res> {
  __$ScanFilterStateCopyWithImpl(this._self, this._then);

  final _ScanFilterState _self;
  final $Res Function(_ScanFilterState) _then;

  /// Create a copy of ScanFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? patientId = freezed,
    Object? dateRange = freezed,
    Object? searchQuery = null,
    Object? statusFilter = freezed,
  }) {
    return _then(_ScanFilterState(
      patientId: freezed == patientId
          ? _self.patientId
          : patientId // ignore: cast_nullable_to_non_nullable
              as String?,
      dateRange: freezed == dateRange
          ? _self.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      statusFilter: freezed == statusFilter
          ? _self.statusFilter
          : statusFilter // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
