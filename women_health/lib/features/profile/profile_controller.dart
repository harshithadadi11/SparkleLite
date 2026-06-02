import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/health_profile.dart';
import '../../data/repositories/mock_backend.dart';
import '../../core/routing/app_router.dart';

part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  @override
  AsyncValue<HealthProfile?> build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      return const AsyncValue.data(null);
    }
    _fetchProfile(user.uid);
    return const AsyncValue.loading();
  }

  Future<void> _fetchProfile(String uid) async {
    try {
      final profile = await ref.read(profileRepoProvider).getProfile(uid);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(HealthProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepoProvider).saveProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
