import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_insight.freezed.dart';
part 'ai_insight.g.dart';

@freezed
class AIInsight with _$AIInsight {
  const factory AIInsight({
    required String id,
    required String userId,
    required String summary,
    required String possiblePattern,
    required String careGuidance,
    required List<String> doctorQuestions,
    required String disclaimer,
    required List<String> sourceLogIds,
    required DateTime createdAt,
  }) = _AIInsight;

  factory AIInsight.fromJson(Map<String, dynamic> json) => _$AIInsightFromJson(json);

  static const String DISCLAIMER = "This is not a medical diagnosis. This app cannot diagnose conditions or replace professional medical advice. Please consult a qualified healthcare provider about any health concerns.";
}
