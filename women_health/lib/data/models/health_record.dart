import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_record.freezed.dart';
part 'health_record.g.dart';

enum RecordType {
  labReport,
  prescription,
  scanReport,
  doctorVisitNote,
  vaccinationRecord,
  other
}

@freezed
class HealthRecord with _$HealthRecord {
  const factory HealthRecord({
    required String id,
    required String userId,
    required String title,
    required RecordType recordType,
    required DateTime recordDate,
    String? doctorName,
    String? fileUrl,
    String? storagePath,
    String? notes,
    @Default(true) bool isPrivate,
    required DateTime createdAt,
  }) = _HealthRecord;

  factory HealthRecord.fromJson(Map<String, dynamic> json) => _$HealthRecordFromJson(json);
}
