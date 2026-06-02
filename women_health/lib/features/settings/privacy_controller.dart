import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/privacy_settings.dart';
import '../../data/repositories/mock_backend.dart';

part 'privacy_controller.g.dart';

@riverpod
class PrivacyController extends _$PrivacyController {
  @override
  FutureOr<PrivacySettings> build() async {
    return _fetchSettings();
  }

  Future<PrivacySettings> _fetchSettings() async {
    final uid = ref.read(authRepoProvider).currentUser!.uid;
    final settings = await ref.read(privacyRepoProvider).getSettings(uid);
    if (settings != null) {
      return settings;
    } else {
      return PrivacySettings.defaults(uid);
    }
  }

  Future<void> updateSettings(PrivacySettings newSettings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(privacyRepoProvider).saveSettings(newSettings);
      return newSettings;
    });
  }
}
