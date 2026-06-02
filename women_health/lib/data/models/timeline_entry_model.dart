import 'package:freezed_annotation/freezed_annotation.dart';

import 'symptom_log.dart';
import 'health_record.dart';

part 'timeline_entry_model.freezed.dart';
part 'timeline_entry_model.g.dart';

enum TimelineEntryType {
  symptomLog,
  healthRecord,
  aiInsight,
  doctorSummary
}

@freezed
class TimelineEntry with _$TimelineEntry {
  const TimelineEntry._();

  const factory TimelineEntry({
    required String id,
    required String userId,
    required String title,
    required String summary,
    required DateTime date,
    required String sourceId,
    required TimelineEntryType entryType,
    required DateTime createdAt,
  }) = _TimelineEntry;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => _$TimelineEntryFromJson(json);

  factory TimelineEntry.fromSymptomLog(SymptomLog log) {
    return TimelineEntry(
      id: 'tl_symp_${log.id}',
      userId: log.userId,
      title: 'Symptom Log',
      summary: log.symptoms.isNotEmpty ? log.symptoms.map((e) => e.name).join(', ') : 'Symptoms Logged',
      date: log.date,
      sourceId: log.id,
      entryType: TimelineEntryType.symptomLog,
      createdAt: log.createdAt,
    );
  }

  factory TimelineEntry.fromHealthRecord(HealthRecord record) {
    return TimelineEntry(
      id: 'tl_rec_${record.id}',
      userId: record.userId,
      title: record.title,
      summary: 'Record Type: ${record.recordType.name}',
      date: record.recordDate,
      sourceId: record.id,
      entryType: TimelineEntryType.healthRecord,
      createdAt: record.createdAt,
    );
  }
}
