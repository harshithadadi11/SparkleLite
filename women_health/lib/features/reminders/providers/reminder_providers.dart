import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/mock_backend.dart';
import '../../../core/routing/app_router.dart';
import '../domain/reminder_model.dart';
import '../data/reminder_repository.dart';

final reminderRepoProvider = Provider<ReminderRepository>((ref) {
  // Using Mock for local dev
  final prefs = ref.watch(sharedPrefsProvider);
  return MockReminderRepository(prefs);
});

final remindersProvider = StreamProvider<List<ReminderModel>>((ref) {
  final user = ref.watch(authRepoProvider).currentUser;
  if (user == null) return Stream.value([]);
  
  final repo = ref.watch(reminderRepoProvider);
  return repo.getReminders(user.uid);
});

final nextReminderProvider = FutureProvider<ReminderModel?>((ref) async {
  final user = ref.watch(authRepoProvider).currentUser;
  if (user == null) return null;
  
  final repo = ref.watch(reminderRepoProvider);
  return repo.getNextReminder(user.uid);
});

final remindersNotifierProvider = AsyncNotifierProvider<RemindersNotifier, void>(() {
  return RemindersNotifier();
});

class RemindersNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> addReminder(ReminderModel reminder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(reminderRepoProvider);
      await repo.addReminder(reminder);
      ref.invalidate(remindersProvider);
      ref.invalidate(nextReminderProvider);
    });
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(reminderRepoProvider);
      await repo.updateReminder(reminder);
      ref.invalidate(remindersProvider);
      ref.invalidate(nextReminderProvider);
    });
  }

  Future<void> deleteReminder(String reminderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepoProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
      
      final repo = ref.read(reminderRepoProvider);
      await repo.deleteReminder(user.uid, reminderId);
      ref.invalidate(remindersProvider);
      ref.invalidate(nextReminderProvider);
    });
  }

  Future<void> toggleReminder(String reminderId, bool isActive) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepoProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
      
      final repo = ref.read(reminderRepoProvider);
      await repo.toggleReminder(user.uid, reminderId, isActive);
      ref.invalidate(remindersProvider);
      ref.invalidate(nextReminderProvider);
    });
  }
}
