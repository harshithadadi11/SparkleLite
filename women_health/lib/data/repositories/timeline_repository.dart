import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/timeline_entry_model.dart';
import '../../data/repositories/mock_backend.dart';

class TimelineRepository {
  final Ref ref;

  TimelineRepository(this.ref);

  Future<List<TimelineEntry>> getCombinedTimeline(String userId) async {
    final logs = await ref.read(symptomRepoProvider).getRecentLogs(userId, 50);
    final records = await ref.read(recordRepoProvider).getRecords(userId);

    final List<TimelineEntry> combined = [
      ...logs.map((l) => TimelineEntry.fromSymptomLog(l)),
      ...records.map((r) => TimelineEntry.fromHealthRecord(r)),
    ];

    combined.sort((a, b) => b.date.compareTo(a.date));
    return combined;
  }
}

final timelineRepoProvider = Provider((ref) => TimelineRepository(ref));
