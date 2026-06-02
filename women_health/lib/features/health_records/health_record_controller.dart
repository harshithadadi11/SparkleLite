import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/health_record.dart';
import '../../data/repositories/mock_backend.dart';
import '../../core/routing/app_router.dart';

part 'health_record_controller.g.dart';

@riverpod
class HealthRecordController extends _$HealthRecordController {
  @override
  AsyncValue<List<HealthRecord>> build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      return const AsyncValue.data([]);
    }
    _fetchRecords(user.uid);
    return const AsyncValue.loading();
  }

  Future<void> _fetchRecords(String uid) async {
    try {
      final records = await ref.read(recordRepoProvider).getRecords(uid);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadRecord({
    required String title,
    required RecordType recordType,
    required DateTime recordDate,
    required bool isPrivate,
    String? doctorName,
    File? file,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception("User not authenticated");
      final record = HealthRecord(
        id: const Uuid().v4(),
        userId: uid,
        title: title,
        recordType: recordType,
        recordDate: recordDate,
        isPrivate: isPrivate,
        doctorName: doctorName,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await ref.read(recordRepoProvider).uploadRecord(record, fileToUpload: file);
      await _fetchRecords(uid);
    } catch (e, st) {
      state = AsyncValue.error(e, st); // Proper error handling
    }
  }
}
