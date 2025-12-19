import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'shift_request_model.freezed.dart';
part 'shift_request_model.g.dart';

@freezed
class ShiftRequestModel with _$ShiftRequestModel {
  const factory ShiftRequestModel({
    required String id,
    required String storeId,
    required String staffId,
    required String type, // "wish", "change", "substitute"
    required String date, // YYYY-MM-DD
    String? startTime, // HH:mm (optional for wish)
    String? endTime, // HH:mm (optional for wish)
    String? reason,
    @Default('pending') String status, // "pending", "approved", "rejected"
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? processedAt,
  }) = _ShiftRequestModel;

  factory ShiftRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ShiftRequestModelFromJson(json);

  factory ShiftRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftRequestModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }
}

DateTime? _timestampFromJson(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is String) return DateTime.parse(timestamp);
  return null;
}

dynamic _timestampToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
