// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StaffModelImpl _$$StaffModelImplFromJson(Map<String, dynamic> json) =>
    _$StaffModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      storeId: json['storeId'] as String,
      name: json['name'] as String,
      hourlyWage: (json['hourlyWage'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$$StaffModelImplToJson(_$StaffModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'storeId': instance.storeId,
      'name': instance.name,
      'hourlyWage': instance.hourlyWage,
      'isActive': instance.isActive,
      'createdAt': _timestampToJson(instance.createdAt),
    };
