import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/doctor_summary.dart';
import '../../data/repositories/mock_backend.dart';
import '../symptom_tracker/symptom_controller.dart';
import '../health_records/health_record_controller.dart';

part 'doctor_summary_controller.g.dart';

@riverpod
class DoctorSummaryController extends _$DoctorSummaryController {
  @override
  AsyncValue<List<DoctorSummary>> build() {
    _fetchSummaries();
    return const AsyncValue.loading();
  }

  Future<void> _fetchSummaries() async {
    try {
      final uid = ref.read(authRepoProvider).currentUser!.uid;
      final summaries = await ref.read(summaryRepoProvider).getSummaries(uid);
      state = AsyncValue.data(summaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateSummary({String? notes, String? medications, List<String>? questions}) async {
    final prev = state;
    state = const AsyncValue.loading();
    try {
      final uid = ref.read(authRepoProvider).currentUser!.uid;
      final summary = await ref.read(summaryRepoProvider).generateSummary(
        userId: uid,
        questionsToAsk: questions ?? [
          "What might be causing my recent symptoms?",
          "Are there any tests you would recommend?",
          "When should I schedule my next check-up?"
        ],
        userNotes: notes,
        medications: medications,
      );

      await ref.read(summaryRepoProvider).saveSummary(summary);
      await _fetchSummaries();
    } catch (e) {
      state = prev;
      rethrow;
    }
  }
}
