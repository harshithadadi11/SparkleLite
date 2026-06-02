import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_profile.freezed.dart';
part 'health_profile.g.dart';

enum LifeStage {
  generalWellness,
  periodTracking,
  fertilityPlanning,
  pregnancy,
  postpartum,
  menopause
}

enum PrivacyLevel {
  standard,
  enhanced
}

@freezed
class HealthProfile with _$HealthProfile {
  const factory HealthProfile({
    required String userId,
    required String nameOrNickname,
    required String ageRange,
    required int age,
    required LifeStage lifeStage,
    String? menstrualCycleStatus,
    List<String>? knownConditions,
    String? medications,
    required PrivacyLevel privacyPreference,
    required bool notificationsEnabled,
    required bool useGenericNotifications,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _HealthProfile;

  factory HealthProfile.fromJson(Map<String, dynamic> json) => _$HealthProfileFromJson(json);
}
