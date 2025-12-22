// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftRequestModelImpl _$$ShiftRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$ShiftRequestModelImpl(
  id: json['id'] as String,
  storeId: json['storeId'] as String,
  staffId: json['staffId'] as String,
  type: json['type'] as String,
  date: json['date'] as String,
  startTime: json['startTime'] as String?,
  endTime: json['endTime'] as String?,
  reason: json['reason'] as String?,
  status: json['status'] as String? ?? AppConstants.requestStatusPending,
  targetShiftId: json['targetShiftId'] as String?,
  volunteerStaffId: json['volunteerStaffId'] as String?,
  createdAt: _timestampFromJson(json['createdAt']),
  processedAt: _timestampFromJson(json['processedAt']),
);

Map<String, dynamic> _$$ShiftRequestModelImplToJson(
  _$ShiftRequestModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'staffId': instance.staffId,
  'type': instance.type,
  'date': instance.date,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'reason': instance.reason,
  'status': instance.status,
  'targetShiftId': instance.targetShiftId,
  'volunteerStaffId': instance.volunteerStaffId,
  'createdAt': _timestampToJson(instance.createdAt),
  'processedAt': _timestampToJson(instance.processedAt),
};
