// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShiftRequestModel _$ShiftRequestModelFromJson(Map<String, dynamic> json) {
  return _ShiftRequestModel.fromJson(json);
}

/// @nodoc
mixin _$ShiftRequestModel {
  String get id => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get staffId => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // "wish", "change", "substitute"
  String get date => throw _privateConstructorUsedError; // YYYY-MM-DD
  String? get startTime =>
      throw _privateConstructorUsedError; // HH:mm (optional for wish)
  String? get endTime =>
      throw _privateConstructorUsedError; // HH:mm (optional for wish)
  String? get reason => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // "pending", "approved", "rejected"
  String? get targetShiftId => throw _privateConstructorUsedError; // 対象シフトID
  String? get volunteerStaffId =>
      throw _privateConstructorUsedError; // 代打志願スタッフID
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  DateTime? get processedAt => throw _privateConstructorUsedError;

  /// Serializes this ShiftRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftRequestModelCopyWith<ShiftRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftRequestModelCopyWith<$Res> {
  factory $ShiftRequestModelCopyWith(
    ShiftRequestModel value,
    $Res Function(ShiftRequestModel) then,
  ) = _$ShiftRequestModelCopyWithImpl<$Res, ShiftRequestModel>;
  @useResult
  $Res call({
    String id,
    String storeId,
    String staffId,
    String type,
    String date,
    String? startTime,
    String? endTime,
    String? reason,
    String status,
    String? targetShiftId,
    String? volunteerStaffId,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? processedAt,
  });
}

/// @nodoc
class _$ShiftRequestModelCopyWithImpl<$Res, $Val extends ShiftRequestModel>
    implements $ShiftRequestModelCopyWith<$Res> {
  _$ShiftRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? staffId = null,
    Object? type = null,
    Object? date = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? reason = freezed,
    Object? status = null,
    Object? targetShiftId = freezed,
    Object? volunteerStaffId = freezed,
    Object? createdAt = freezed,
    Object? processedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            storeId: null == storeId
                ? _value.storeId
                : storeId // ignore: cast_nullable_to_non_nullable
                      as String,
            staffId: null == staffId
                ? _value.staffId
                : staffId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            targetShiftId: freezed == targetShiftId
                ? _value.targetShiftId
                : targetShiftId // ignore: cast_nullable_to_non_nullable
                      as String?,
            volunteerStaffId: freezed == volunteerStaffId
                ? _value.volunteerStaffId
                : volunteerStaffId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            processedAt: freezed == processedAt
                ? _value.processedAt
                : processedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShiftRequestModelImplCopyWith<$Res>
    implements $ShiftRequestModelCopyWith<$Res> {
  factory _$$ShiftRequestModelImplCopyWith(
    _$ShiftRequestModelImpl value,
    $Res Function(_$ShiftRequestModelImpl) then,
  ) = __$$ShiftRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String storeId,
    String staffId,
    String type,
    String date,
    String? startTime,
    String? endTime,
    String? reason,
    String status,
    String? targetShiftId,
    String? volunteerStaffId,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? processedAt,
  });
}

/// @nodoc
class __$$ShiftRequestModelImplCopyWithImpl<$Res>
    extends _$ShiftRequestModelCopyWithImpl<$Res, _$ShiftRequestModelImpl>
    implements _$$ShiftRequestModelImplCopyWith<$Res> {
  __$$ShiftRequestModelImplCopyWithImpl(
    _$ShiftRequestModelImpl _value,
    $Res Function(_$ShiftRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? staffId = null,
    Object? type = null,
    Object? date = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? reason = freezed,
    Object? status = null,
    Object? targetShiftId = freezed,
    Object? volunteerStaffId = freezed,
    Object? createdAt = freezed,
    Object? processedAt = freezed,
  }) {
    return _then(
      _$ShiftRequestModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        storeId: null == storeId
            ? _value.storeId
            : storeId // ignore: cast_nullable_to_non_nullable
                  as String,
        staffId: null == staffId
            ? _value.staffId
            : staffId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        targetShiftId: freezed == targetShiftId
            ? _value.targetShiftId
            : targetShiftId // ignore: cast_nullable_to_non_nullable
                  as String?,
        volunteerStaffId: freezed == volunteerStaffId
            ? _value.volunteerStaffId
            : volunteerStaffId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        processedAt: freezed == processedAt
            ? _value.processedAt
            : processedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftRequestModelImpl implements _ShiftRequestModel {
  const _$ShiftRequestModelImpl({
    required this.id,
    required this.storeId,
    required this.staffId,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    this.reason,
    this.status = 'pending',
    this.targetShiftId,
    this.volunteerStaffId,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    this.createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    this.processedAt,
  });

  factory _$ShiftRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftRequestModelImplFromJson(json);

  @override
  final String id;
  @override
  final String storeId;
  @override
  final String staffId;
  @override
  final String type;
  // "wish", "change", "substitute"
  @override
  final String date;
  // YYYY-MM-DD
  @override
  final String? startTime;
  // HH:mm (optional for wish)
  @override
  final String? endTime;
  // HH:mm (optional for wish)
  @override
  final String? reason;
  @override
  @JsonKey()
  final String status;
  // "pending", "approved", "rejected"
  @override
  final String? targetShiftId;
  // 対象シフトID
  @override
  final String? volunteerStaffId;
  // 代打志願スタッフID
  @override
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? createdAt;
  @override
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? processedAt;

  @override
  String toString() {
    return 'ShiftRequestModel(id: $id, storeId: $storeId, staffId: $staffId, type: $type, date: $date, startTime: $startTime, endTime: $endTime, reason: $reason, status: $status, targetShiftId: $targetShiftId, volunteerStaffId: $volunteerStaffId, createdAt: $createdAt, processedAt: $processedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftRequestModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.staffId, staffId) || other.staffId == staffId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.targetShiftId, targetShiftId) ||
                other.targetShiftId == targetShiftId) &&
            (identical(other.volunteerStaffId, volunteerStaffId) ||
                other.volunteerStaffId == volunteerStaffId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    storeId,
    staffId,
    type,
    date,
    startTime,
    endTime,
    reason,
    status,
    targetShiftId,
    volunteerStaffId,
    createdAt,
    processedAt,
  );

  /// Create a copy of ShiftRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftRequestModelImplCopyWith<_$ShiftRequestModelImpl> get copyWith =>
      __$$ShiftRequestModelImplCopyWithImpl<_$ShiftRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftRequestModelImplToJson(this);
  }
}

abstract class _ShiftRequestModel implements ShiftRequestModel {
  const factory _ShiftRequestModel({
    required final String id,
    required final String storeId,
    required final String staffId,
    required final String type,
    required final String date,
    final String? startTime,
    final String? endTime,
    final String? reason,
    final String status,
    final String? targetShiftId,
    final String? volunteerStaffId,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    final DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    final DateTime? processedAt,
  }) = _$ShiftRequestModelImpl;

  factory _ShiftRequestModel.fromJson(Map<String, dynamic> json) =
      _$ShiftRequestModelImpl.fromJson;

  @override
  String get id;
  @override
  String get storeId;
  @override
  String get staffId;
  @override
  String get type; // "wish", "change", "substitute"
  @override
  String get date; // YYYY-MM-DD
  @override
  String? get startTime; // HH:mm (optional for wish)
  @override
  String? get endTime; // HH:mm (optional for wish)
  @override
  String? get reason;
  @override
  String get status; // "pending", "approved", "rejected"
  @override
  String? get targetShiftId; // 対象シフトID
  @override
  String? get volunteerStaffId; // 代打志願スタッフID
  @override
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  DateTime? get createdAt;
  @override
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  DateTime? get processedAt;

  /// Create a copy of ShiftRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftRequestModelImplCopyWith<_$ShiftRequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
