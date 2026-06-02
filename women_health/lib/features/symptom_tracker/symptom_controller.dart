import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/symptom_log.dart';
import '../../data/repositories/mock_backend.dart';
import '../../core/routing/app_router.dart';

part 'symptom_controller.g.dart';

@riverpod
class SymptomController extends _$SymptomController {
  @override
  FutureOr<List<SymptomLog>> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return [];
    return _fetchLogs(user.uid);
  }

  Future<List<SymptomLog>> _fetchLogs(String uid) async {
    return await ref.read(symptomRepoProvider).getRecentLogs(uid, 50);
  }

  Future<void> addLog(SymptomLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(symptomRepoProvider).addLog(log);
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception("User not authenticated");
      return _fetchLogs(uid);
    });
  }

  Future<void> deleteLog(String logId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception("User not authenticated");
      await ref.read(symptomRepoProvider).deleteLog(uid, logId);
      return _fetchLogs(uid);
    });
  }
}
