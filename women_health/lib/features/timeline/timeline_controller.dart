import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/timeline_entry_model.dart';
import '../symptom_tracker/symptom_controller.dart';
import '../health_records/health_record_controller.dart';

part 'timeline_controller.g.dart';

@riverpod
class TimelineController extends _$TimelineController {
  @override
  AsyncValue<List<TimelineEntry>> build() {
    final logsState = ref.watch(symptomControllerProvider);
    final recordsState = ref.watch(healthRecordControllerProvider);

    if (logsState.isLoading || recordsState.isLoading) {
      return const AsyncValue.loading();
    }

    if (logsState.hasError) {
      return AsyncValue.error(logsState.error!, logsState.stackTrace!);
    }
    
    if (recordsState.hasError) {
      return AsyncValue.error(recordsState.error!, recordsState.stackTrace!);
    }

    final List<TimelineEntry> combined = [];

    if (logsState.hasValue) {
      final logs = logsState.value!;
      combined.addAll(logs.map((log) => TimelineEntry.fromSymptomLog(log)));
    }

    if (recordsState.hasValue) {
      final records = recordsState.value!;
      combined.addAll(records.map((record) => TimelineEntry.fromHealthRecord(record)));
    }

    // Sort descending by date
    combined.sort((a, b) => b.date.compareTo(a.date));

    return AsyncValue.data(combined);
  }
}
