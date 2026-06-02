import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom_log.freezed.dart';
part 'symptom_log.g.dart';

enum PeriodStatus {
  noPeriod,
  started,
  ongoing,
  ended
}

enum FlowLevel {
  none,
  light,
  medium,
  heavy
}

enum Mood {
  calm,
  anxious,
  tired,
  irritable,
  happy,
  sad
}

enum Symptom {
  cramps,
  headache,
  bloating,
  fatigue,
  nausea,
  spotting,
  irregularBleeding,
  other
}

@freezed
class SymptomLog with _$SymptomLog {
  const factory SymptomLog({
    required String id,
    required String userId,
    required DateTime date,
    required PeriodStatus periodStatus,
    required FlowLevel flowLevel,
    required int painLevel,
    required Mood mood,
    required List<Symptom> symptoms,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SymptomLog;

  factory SymptomLog.fromJson(Map<String, dynamic> json) => _$SymptomLogFromJson(json);
}
