// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftModelImpl _$$ShiftModelImplFromJson(Map<String, dynamic> json) =>
    _$ShiftModelImpl(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      staffId: json['staffId'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String? ?? 'draft',
      createdAt: _timestampFromJson(json['createdAt']),
      updatedAt: _timestampFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$ShiftModelImplToJson(_$ShiftModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'staffId': instance.staffId,
      'date': instance.date,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'status': instance.status,
      'createdAt': _timestampToJson(instance.createdAt),
      'updatedAt': _timestampToJson(instance.updatedAt),
    };
