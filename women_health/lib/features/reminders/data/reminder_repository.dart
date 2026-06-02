import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/reminder_model.dart';

abstract class ReminderRepository {
  Stream<List<ReminderModel>> getReminders(String userId);
  Future<ReminderModel?> getNextReminder(String userId);
  Future<void> addReminder(ReminderModel reminder);
  Future<void> updateReminder(ReminderModel reminder);
  Future<void> deleteReminder(String userId, String reminderId);
  Future<void> toggleReminder(String userId, String reminderId, bool isActive);
}

class FirebaseReminderRepository implements ReminderRepository {
  final FirebaseFirestore _firestore;

  FirebaseReminderRepository(this._firestore);

  @override
  Stream<List<ReminderModel>> getReminders(String userId) {
    return _firestore
        .collection('reminders')
        .doc(userId)
        .collection('items')
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReminderModel.fromJson(doc.data())).toList());
  }

  DateTime _calculateNextOccurrence(ReminderModel reminder) {
    final now = DateTime.now();
    if (reminder.scheduledTime.isAfter(now) || reminder.repeat == ReminderRepeat.none) {
      return reminder.scheduledTime;
    }
    
    DateTime next = reminder.scheduledTime;
    while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      switch (reminder.repeat) {
        case ReminderRepeat.daily:
          next = DateTime(next.year, next.month, next.day + 1, next.hour, next.minute);
          break;
        case ReminderRepeat.weekly:
          next = DateTime(next.year, next.month, next.day + 7, next.hour, next.minute);
          break;
        case ReminderRepeat.monthly:
          next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
          break;
        case ReminderRepeat.none:
          break;
      }
    }
    return next;
  }

  @override
  Future<ReminderModel?> getNextReminder(String userId) async {
    final querySnapshot = await _firestore
        .collection('reminders')
        .doc(userId)
        .collection('items')
        .where('isActive', isEqualTo: true)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final reminders = querySnapshot.docs.map((d) => ReminderModel.fromJson(d.data())).toList();
    
    final now = DateTime.now();
    final upcoming = reminders.where((r) => _calculateNextOccurrence(r).isAfter(now)).toList();
    
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => _calculateNextOccurrence(a).compareTo(_calculateNextOccurrence(b)));
    
    // Return a copy with the scheduledTime updated to the next occurrence
    // so the UI shows the correct next time
    final nextReminder = upcoming.first;
    return nextReminder.copyWith(scheduledTime: _calculateNextOccurrence(nextReminder));
  }

  @override
  Future<void> addReminder(ReminderModel reminder) async {
    await _firestore
        .collection('reminders')
        .doc(reminder.userId)
        .collection('items')
        .doc(reminder.id)
        .set(reminder.toJson());
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    await _firestore
        .collection('reminders')
        .doc(reminder.userId)
        .collection('items')
        .doc(reminder.id)
        .update(reminder.toJson());
  }

  @override
  Future<void> deleteReminder(String userId, String reminderId) async {
    await _firestore
        .collection('reminders')
        .doc(userId)
        .collection('items')
        .doc(reminderId)
        .delete();
  }

  @override
  Future<void> toggleReminder(String userId, String reminderId, bool isActive) async {
    await _firestore
        .collection('reminders')
        .doc(userId)
        .collection('items')
        .doc(reminderId)
        .update({'isActive': isActive});
  }
}

class MockReminderRepository implements ReminderRepository {
  final SharedPreferences _prefs;
  final List<ReminderModel> _reminders = [];

  MockReminderRepository(this._prefs) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final jsonStr = _prefs.getString('mock_reminders_json');
    if (jsonStr != null) {
      try {
        final list = json.decode(jsonStr) as List<dynamic>;
        _reminders.clear();
        _reminders.addAll(
          list.map((item) => ReminderModel.fromJson(item as Map<String, dynamic>)),
        );
      } catch (e) {
        // ignore and fallback
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final list = _reminders.map((r) => r.toLocalJson()).toList();
    await _prefs.setString('mock_reminders_json', json.encode(list));
  }

  @override
  Stream<List<ReminderModel>> getReminders(String userId) async* {
    _loadFromPrefs();
    final userReminders = _reminders.where((r) => r.userId == userId).toList();
    userReminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    yield userReminders;
  }

  @override
  Future<ReminderModel?> getNextReminder(String userId) async {
    _loadFromPrefs();
    final now = DateTime.now();
    
    DateTime calcNext(ReminderModel r) {
      if (r.scheduledTime.isAfter(now) || r.repeat == ReminderRepeat.none) return r.scheduledTime;
      DateTime next = r.scheduledTime;
      while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
        switch (r.repeat) {
          case ReminderRepeat.daily: next = DateTime(next.year, next.month, next.day + 1, next.hour, next.minute); break;
          case ReminderRepeat.weekly: next = DateTime(next.year, next.month, next.day + 7, next.hour, next.minute); break;
          case ReminderRepeat.monthly: next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute); break;
          case ReminderRepeat.none: break;
        }
      }
      return next;
    }

    final upcoming = _reminders
        .where((r) => r.userId == userId && r.isActive && calcNext(r).isAfter(now))
        .toList();
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => calcNext(a).compareTo(calcNext(b)));
    final nextReminder = upcoming.first;
    return nextReminder.copyWith(scheduledTime: calcNext(nextReminder));
  }

  @override
  Future<void> addReminder(ReminderModel reminder) async {
    _loadFromPrefs();
    _reminders.add(reminder);
    await _saveToPrefs();
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    _loadFromPrefs();
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      await _saveToPrefs();
    }
  }

  @override
  Future<void> deleteReminder(String userId, String reminderId) async {
    _loadFromPrefs();
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveToPrefs();
  }

  @override
  Future<void> toggleReminder(String userId, String reminderId, bool isActive) async {
    _loadFromPrefs();
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isActive: isActive);
      await _saveToPrefs();
    }
  }
}
