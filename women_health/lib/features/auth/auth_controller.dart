import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/mock_backend.dart';
import '../../core/routing/app_router.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepoProvider).login(email, password);
      await ref.read(sharedPrefsProvider).setBool('is_logged_in', true);
      ref.read(localAuthSuccessProvider.notifier).state = true;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signup(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepoProvider).signUp(email, password);
      await ref.read(sharedPrefsProvider).setBool('is_logged_in', true);
      ref.read(localAuthSuccessProvider.notifier).state = true;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepoProvider).logout();
      await ref.read(sharedPrefsProvider).setBool('is_logged_in', false);
      ref.read(localAuthSuccessProvider.notifier).state = false;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
