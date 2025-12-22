// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreModelImpl _$$StoreModelImplFromJson(Map<String, dynamic> json) =>
    _$StoreModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      plan: json['plan'] as String? ?? AppConstants.planFree,
      businessHours: json['businessHours'] as Map<String, dynamic>? ?? const {},
      shiftUnitMinutes: (json['shiftUnitMinutes'] as num?)?.toInt() ?? 30,
      weekStart: (json['weekStart'] as num?)?.toInt() ?? 0,
      createdAt: _timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$$StoreModelImplToJson(_$StoreModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ownerId': instance.ownerId,
      'plan': instance.plan,
      'businessHours': instance.businessHours,
      'shiftUnitMinutes': instance.shiftUnitMinutes,
      'weekStart': instance.weekStart,
      'createdAt': _timestampToJson(instance.createdAt),
    };
