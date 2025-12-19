// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StoreModel _$StoreModelFromJson(Map<String, dynamic> json) {
  return _StoreModel.fromJson(json);
}

/// @nodoc
mixin _$StoreModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get plan =>
      throw _privateConstructorUsedError; // "free", "basic", "pro"
  Map<String, dynamic> get businessHours => throw _privateConstructorUsedError;
  int get shiftUnitMinutes => throw _privateConstructorUsedError;
  int get weekStart => throw _privateConstructorUsedError; // 0 = Sunday
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this StoreModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreModelCopyWith<StoreModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreModelCopyWith<$Res> {
  factory $StoreModelCopyWith(
    StoreModel value,
    $Res Function(StoreModel) then,
  ) = _$StoreModelCopyWithImpl<$Res, StoreModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String ownerId,
    String plan,
    Map<String, dynamic> businessHours,
    int shiftUnitMinutes,
    int weekStart,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
  });
}

/// @nodoc
class _$StoreModelCopyWithImpl<$Res, $Val extends StoreModel>
    implements $StoreModelCopyWith<$Res> {
  _$StoreModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ownerId = null,
    Object? plan = null,
    Object? businessHours = null,
    Object? shiftUnitMinutes = null,
    Object? weekStart = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
            plan: null == plan
                ? _value.plan
                : plan // ignore: cast_nullable_to_non_nullable
                      as String,
            businessHours: null == businessHours
                ? _value.businessHours
                : businessHours // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            shiftUnitMinutes: null == shiftUnitMinutes
                ? _value.shiftUnitMinutes
                : shiftUnitMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            weekStart: null == weekStart
                ? _value.weekStart
                : weekStart // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StoreModelImplCopyWith<$Res>
    implements $StoreModelCopyWith<$Res> {
  factory _$$StoreModelImplCopyWith(
    _$StoreModelImpl value,
    $Res Function(_$StoreModelImpl) then,
  ) = __$$StoreModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String ownerId,
    String plan,
    Map<String, dynamic> businessHours,
    int shiftUnitMinutes,
    int weekStart,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$StoreModelImplCopyWithImpl<$Res>
    extends _$StoreModelCopyWithImpl<$Res, _$StoreModelImpl>
    implements _$$StoreModelImplCopyWith<$Res> {
  __$$StoreModelImplCopyWithImpl(
    _$StoreModelImpl _value,
    $Res Function(_$StoreModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ownerId = null,
    Object? plan = null,
    Object? businessHours = null,
    Object? shiftUnitMinutes = null,
    Object? weekStart = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$StoreModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        plan: null == plan
            ? _value.plan
            : plan // ignore: cast_nullable_to_non_nullable
                  as String,
        businessHours: null == businessHours
            ? _value._businessHours
            : businessHours // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        shiftUnitMinutes: null == shiftUnitMinutes
            ? _value.shiftUnitMinutes
            : shiftUnitMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        weekStart: null == weekStart
            ? _value.weekStart
            : weekStart // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreModelImpl implements _StoreModel {
  const _$StoreModelImpl({
    required this.id,
    required this.name,
    required this.ownerId,
    this.plan = 'free',
    final Map<String, dynamic> businessHours = const {},
    this.shiftUnitMinutes = 30,
    this.weekStart = 0,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    this.createdAt,
  }) : _businessHours = businessHours;

  factory _$StoreModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String ownerId;
  @override
  @JsonKey()
  final String plan;
  // "free", "basic", "pro"
  final Map<String, dynamic> _businessHours;
  // "free", "basic", "pro"
  @override
  @JsonKey()
  Map<String, dynamic> get businessHours {
    if (_businessHours is EqualUnmodifiableMapView) return _businessHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_businessHours);
  }

  @override
  @JsonKey()
  final int shiftUnitMinutes;
  @override
  @JsonKey()
  final int weekStart;
  // 0 = Sunday
  @override
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? createdAt;

  @override
  String toString() {
    return 'StoreModel(id: $id, name: $name, ownerId: $ownerId, plan: $plan, businessHours: $businessHours, shiftUnitMinutes: $shiftUnitMinutes, weekStart: $weekStart, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.plan, plan) || other.plan == plan) &&
            const DeepCollectionEquality().equals(
              other._businessHours,
              _businessHours,
            ) &&
            (identical(other.shiftUnitMinutes, shiftUnitMinutes) ||
                other.shiftUnitMinutes == shiftUnitMinutes) &&
            (identical(other.weekStart, weekStart) ||
                other.weekStart == weekStart) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    ownerId,
    plan,
    const DeepCollectionEquality().hash(_businessHours),
    shiftUnitMinutes,
    weekStart,
    createdAt,
  );

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreModelImplCopyWith<_$StoreModelImpl> get copyWith =>
      __$$StoreModelImplCopyWithImpl<_$StoreModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreModelImplToJson(this);
  }
}

abstract class _StoreModel implements StoreModel {
  const factory _StoreModel({
    required final String id,
    required final String name,
    required final String ownerId,
    final String plan,
    final Map<String, dynamic> businessHours,
    final int shiftUnitMinutes,
    final int weekStart,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    final DateTime? createdAt,
  }) = _$StoreModelImpl;

  factory _StoreModel.fromJson(Map<String, dynamic> json) =
      _$StoreModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get ownerId;
  @override
  String get plan; // "free", "basic", "pro"
  @override
  Map<String, dynamic> get businessHours;
  @override
  int get shiftUnitMinutes;
  @override
  int get weekStart; // 0 = Sunday
  @override
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  DateTime? get createdAt;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreModelImplCopyWith<_$StoreModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
