import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ai_insight.dart';
import '../../data/repositories/mock_backend.dart';
import '../symptom_tracker/symptom_controller.dart';
import '../../data/models/symptom_log.dart';

part 'ai_insight_controller.g.dart';

@riverpod
class AiInsightController extends _$AiInsightController {
  @override
  AsyncValue<List<AIInsight>> build() {
    _fetchInsights();
    return const AsyncValue.loading();
  }

  Future<void> _fetchInsights() async {
    try {
      final uid = ref.read(authRepoProvider).currentUser!.uid;
      final insights = await ref.read(insightRepoProvider).getInsights(uid);
      state = AsyncValue.data(insights);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AIInsight> generateInsightFromSymptoms(List<String> logIds) async {
    if (logIds.isEmpty) {
      throw Exception('No recent logs selected to analyze.');
    }
    
    final uid = ref.read(authRepoProvider).currentUser!.uid;
    final insight = await ref.read(insightRepoProvider).generateInsight(uid, logIds);
    return insight;
  }
  
  Future<void> saveInsight(AIInsight insight) async {
    final prev = state;
    state = const AsyncValue.loading();
    try {
      await ref.read(insightRepoProvider).saveInsight(insight);
      await _fetchInsights();
    } catch (e) {
      state = prev;
      rethrow;
    }
  }
}
