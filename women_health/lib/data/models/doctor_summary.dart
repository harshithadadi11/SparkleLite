import 'package:freezed_annotation/freezed_annotation.dart';

part 'doctor_summary.freezed.dart';
part 'doctor_summary.g.dart';

@freezed
class DoctorSummary with _$DoctorSummary {
  const factory DoctorSummary({
    required String id,
    required String userId,
    required String summaryText,
    required Map<String, dynamic> profileSnapshot,
    required List<Map<String, dynamic>> recentSymptomLogs,
    required List<Map<String, dynamic>> recentRecords,
    String? medications,
    required List<String> questionsToAsk,
    String? userNotes,
    required DateTime generatedAt,
  }) = _DoctorSummary;

  factory DoctorSummary.fromJson(Map<String, dynamic> json) => _$DoctorSummaryFromJson(json);
}
