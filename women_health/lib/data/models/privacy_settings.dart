import 'package:freezed_annotation/freezed_annotation.dart';

part 'privacy_settings.freezed.dart';
part 'privacy_settings.g.dart';

@freezed
class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    required String userId,
    required bool hideSensitiveDashboardDetails,
    required bool useGenericNotificationText,
    required bool requireConfirmationBeforeSharing,
    required bool familyProfileAccessEnabled,
    required DateTime updatedAt,
  }) = _PrivacySettings;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => _$PrivacySettingsFromJson(json);

  factory PrivacySettings.defaults(String userId) {
    return PrivacySettings(
      userId: userId,
      hideSensitiveDashboardDetails: true,
      useGenericNotificationText: true,
      requireConfirmationBeforeSharing: true,
      familyProfileAccessEnabled: false,
      updatedAt: DateTime.now(),
    );
  }
}
