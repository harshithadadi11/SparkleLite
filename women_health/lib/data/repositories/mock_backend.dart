import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import 'firebase_auth_repository.dart';
import 'firebase_profile_repository.dart';
import 'firebase_symptom_repository.dart';
import 'firebase_record_repository.dart';
import 'firebase_privacy_repository.dart';
import 'firebase_family_repository.dart';
import 'firebase_summary_repository.dart';
import 'firebase_insight_repository.dart';
import '../../core/routing/app_router.dart';

import '../models/symptom_log.dart';
import '../models/health_record.dart';
import '../models/ai_insight.dart';
import '../models/doctor_summary.dart';
import '../models/family_member.dart';
import '../models/health_profile.dart';
import '../models/privacy_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/doctor_summary/data/summary_builder_service.dart';
import 'dart:io';

// --- MOCK DATABASE ---
class MockDatabase {
  String? currentUser;
  HealthProfile? profile;
  PrivacySettings? privacySettings;
  
  final List<SymptomLog> symptomLogs = [];
  final List<HealthRecord> healthRecords = [];
  
  final List<AIInsight> aiInsights = [
    AIInsight(
      id: 'mock_insight_1',
      userId: 'mock_user_123',
      summary: 'Hydration could improve your fatigue.',
      possiblePattern: 'You reported fatigue on days with low water intake.',
      careGuidance: 'Try drinking an extra glass of water.',
      doctorQuestions: ['Should I be worried about this fatigue?'],
      disclaimer: AIInsight.DISCLAIMER,
      sourceLogIds: [],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AIInsight(
      id: 'mock_insight_2',
      userId: 'mock_user_123',
      summary: 'Your sleep patterns look stable.',
      possiblePattern: 'No irregular sleep disturbances detected.',
      careGuidance: 'Keep up the good work.',
      doctorQuestions: [],
      disclaimer: AIInsight.DISCLAIMER,
      sourceLogIds: [],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
  
  final List<DoctorSummary> doctorSummaries = [
    DoctorSummary(
      id: 'mock_summary_1',
      userId: 'mock_user_123',
      summaryText: 'This is a mock summary text.',
      profileSnapshot: {'name': 'Mock User'},
      recentSymptomLogs: [],
      recentRecords: [],
      questionsToAsk: ['Are these cramps normal?'],
      generatedAt: DateTime.now().subtract(const Duration(days: 5)),
    )
  ];
  
  final List<FamilyMember> familyMembers = [];
  
  static final MockDatabase instance = MockDatabase._();
  MockDatabase._();
}

// Set this to true to run the entire app offline with Mock Repositories
const bool useMockBackend = true;

// --- PROVIDERS ---
final authRepoProvider = Provider((ref) {
  if (useMockBackend) {
    final prefs = ref.watch(sharedPrefsProvider);
    return MockAuthRepository(prefs) as dynamic;
  }
  return FirebaseAuthRepository(FirebaseAuth.instance);
});
final profileRepoProvider = Provider((ref) {
  if (useMockBackend) {
    final prefs = ref.watch(sharedPrefsProvider);
    return MockProfileRepository(prefs) as dynamic;
  }
  return FirebaseProfileRepository(FirebaseFirestore.instance);
});
final symptomRepoProvider = Provider((ref) {
  if (useMockBackend) {
    final prefs = ref.watch(sharedPrefsProvider);
    return MockSymptomRepository(prefs) as dynamic;
  }
  return FirebaseSymptomRepository(FirebaseFirestore.instance);
});
final recordRepoProvider = Provider((ref) {
  if (useMockBackend) {
    final prefs = ref.watch(sharedPrefsProvider);
    return MockRecordRepository(prefs) as dynamic;
  }
  return FirebaseRecordRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});
final insightRepoProvider = Provider((ref) => useMockBackend ? MockInsightRepository() as dynamic : FirebaseInsightRepository(FirebaseFirestore.instance, FirebaseFunctions.instance));
final summaryRepoProvider = Provider((ref) => useMockBackend ? MockSummaryRepository() as dynamic : FirebaseSummaryRepository(FirebaseFirestore.instance, FirebaseFunctions.instance));
final privacyRepoProvider = Provider((ref) => useMockBackend ? MockPrivacyRepository() as dynamic : FirebasePrivacyRepository(FirebaseFirestore.instance));
final familyRepoProvider = Provider((ref) => useMockBackend ? MockFamilyRepository() as dynamic : FirebaseFamilyRepository(FirebaseFirestore.instance));

class MockUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  MockUser({required this.uid, this.email});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- REPOSITORIES ---
class MockAuthRepository {
  final SharedPreferences _prefs;
  final _controller = StreamController<User?>.broadcast();

  MockAuthRepository(this._prefs) {
    // Start session persistence based on SharedPreferences
    final isLoggedIn = _prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn) {
      MockDatabase.instance.currentUser = 'mock_user_123';
    } else {
      MockDatabase.instance.currentUser = null;
    }
  }

  Stream<User?> get authStateChanges async* {
    yield currentUser;
    yield* _controller.stream;
  }

  User? get currentUser => MockDatabase.instance.currentUser != null
      ? MockUser(uid: MockDatabase.instance.currentUser!)
      : null;

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.isEmpty || password.isEmpty) throw Exception('Invalid credentials');
    MockDatabase.instance.currentUser = 'mock_user_123';
    await _prefs.setBool('is_logged_in', true);
    _controller.add(currentUser);
  }

  Future<void> signUp(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password.length < 8) throw Exception('Password too short');
    MockDatabase.instance.currentUser = 'mock_user_123';
    await _prefs.setBool('is_logged_in', true);
    _controller.add(currentUser);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    MockDatabase.instance.currentUser = null;
    MockDatabase.instance.profile = null;
    MockDatabase.instance.symptomLogs.clear();
    MockDatabase.instance.healthRecords.clear();
    await _prefs.setBool('is_logged_in', false);
    _controller.add(null);
  }

  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));
    MockDatabase.instance.currentUser = null;
    MockDatabase.instance.profile = null;
    MockDatabase.instance.symptomLogs.clear();
    MockDatabase.instance.healthRecords.clear();
    await _prefs.setBool('is_logged_in', false);
    await _prefs.remove('mock_profile_json');
    await _prefs.remove('mock_symptoms_json');
    await _prefs.remove('mock_records_json');
    _controller.add(null);
  }
}

class MockProfileRepository {
  final SharedPreferences _prefs;

  MockProfileRepository(this._prefs);

  Future<HealthProfile?> getProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final jsonStr = _prefs.getString('mock_profile_json');
    if (jsonStr != null) {
      try {
        final profile = HealthProfile.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
        MockDatabase.instance.profile = profile;
        return profile;
      } catch (e) {
        // ignore and fallback
      }
    }
    return MockDatabase.instance.profile;
  }

  Future<void> saveProfile(HealthProfile profile) async {
    await Future.delayed(const Duration(seconds: 1));
    MockDatabase.instance.profile = profile;
    await _prefs.setString('mock_profile_json', json.encode(profile.toJson()));
  }
}

class MockSymptomRepository {
  final SharedPreferences _prefs;

  MockSymptomRepository(this._prefs) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final jsonStr = _prefs.getString('mock_symptoms_json');
    if (jsonStr != null) {
      try {
        final list = json.decode(jsonStr) as List<dynamic>;
        MockDatabase.instance.symptomLogs.clear();
        MockDatabase.instance.symptomLogs.addAll(
          list.map((item) => SymptomLog.fromJson(item as Map<String, dynamic>)),
        );
      } catch (e) {
        // ignore and fallback
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final list = MockDatabase.instance.symptomLogs.map((l) => l.toJson()).toList();
    await _prefs.setString('mock_symptoms_json', json.encode(list));
  }

  Future<List<SymptomLog>> getLogs(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadFromPrefs();
    return List.from(MockDatabase.instance.symptomLogs.where((l) => l.userId == userId));
  }

  Future<List<SymptomLog>> getRecentLogs(String userId, int limit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadFromPrefs();
    return MockDatabase.instance.symptomLogs
        .where((l) => l.userId == userId)
        .take(limit)
        .toList();
  }

  Future<void> addLog(SymptomLog log) async {
    await Future.delayed(const Duration(seconds: 1));
    final logToSave = log.id.isEmpty ? log.copyWith(id: const Uuid().v4()) : log;
    
    // Ensure we don't have duplicates if updating
    final index = MockDatabase.instance.symptomLogs.indexWhere((l) => l.id == logToSave.id);
    if (index != -1) {
      MockDatabase.instance.symptomLogs[index] = logToSave;
    } else {
      MockDatabase.instance.symptomLogs.insert(0, logToSave);
    }
    await _saveToPrefs();
  }

  Future<void> deleteLog(String userId, String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    MockDatabase.instance.symptomLogs.removeWhere((l) => l.id == id && l.userId == userId);
    await _saveToPrefs();
  }
}

class MockRecordRepository {
  final SharedPreferences _prefs;

  MockRecordRepository(this._prefs) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final jsonStr = _prefs.getString('mock_records_json');
    if (jsonStr != null) {
      try {
        final list = json.decode(jsonStr) as List<dynamic>;
        MockDatabase.instance.healthRecords.clear();
        MockDatabase.instance.healthRecords.addAll(
          list.map((item) => HealthRecord.fromJson(item as Map<String, dynamic>)),
        );
      } catch (e) {
        // ignore and fallback
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final list = MockDatabase.instance.healthRecords.map((r) => r.toJson()).toList();
    await _prefs.setString('mock_records_json', json.encode(list));
  }

  Future<List<HealthRecord>> getRecords(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadFromPrefs();
    return List.from(MockDatabase.instance.healthRecords);
  }

  Future<void> uploadRecord(HealthRecord record, {File? fileToUpload}) async {
    await Future.delayed(const Duration(seconds: 2));
    final recordToSave = record.fileUrl == null && fileToUpload != null
        ? record.copyWith(fileUrl: 'mock_file_url_path/${fileToUpload.path.split(RegExp(r"[/\\]")).last}')
        : record;
    MockDatabase.instance.healthRecords.insert(0, recordToSave);
    await _saveToPrefs();
  }
}

class MockInsightRepository {
  Future<List<AIInsight>> getInsights(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(MockDatabase.instance.aiInsights);
  }

  Future<void> saveInsight(AIInsight insight) async {
    await Future.delayed(const Duration(milliseconds: 500));
    MockDatabase.instance.aiInsights.insert(0, insight);
  }

  Future<AIInsight> generateInsight(String userId, List<String> logIds) async {
    await Future.delayed(const Duration(seconds: 2));
    final newInsight = AIInsight(
      id: const Uuid().v4(),
      userId: userId,
      summary: 'Stress levels observed alongside light cramps.',
      possiblePattern: 'Consider tracking stress triggers.',
      careGuidance: 'Try relaxation techniques.',
      doctorQuestions: [],
      disclaimer: AIInsight.DISCLAIMER,
      sourceLogIds: [],
      createdAt: DateTime.now(),
    );
    return newInsight;
  }
}

class MockSummaryRepository {
  Future<List<DoctorSummary>> getSummaries(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(MockDatabase.instance.doctorSummaries);
  }

  Future<void> saveSummary(DoctorSummary summary) async {
    await Future.delayed(const Duration(seconds: 1));
    MockDatabase.instance.doctorSummaries.insert(0, summary);
  }

  Future<DoctorSummary> generateSummary({
    required String userId,
    required List<String> questionsToAsk,
    String? userNotes,
    String? medications,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final profile = MockDatabase.instance.profile;
    final logs = MockDatabase.instance.symptomLogs;
    final records = MockDatabase.instance.healthRecords;
    
    final builder = SummaryBuilderService();
    final summaryText = builder.buildSummaryText(
      profile: profile,
      recentLogs: logs,
      recentRecords: records,
      questionsToAsk: questionsToAsk,
      userNotes: userNotes,
      medications: medications,
    );

    return DoctorSummary(
      id: const Uuid().v4(),
      userId: userId,
      summaryText: summaryText,
      profileSnapshot: profile?.toJson() ?? {},
      recentSymptomLogs: logs.map((l) => l.toJson()).toList(),
      recentRecords: records.map((r) => r.toJson()).toList(),
      medications: medications,
      questionsToAsk: questionsToAsk,
      userNotes: userNotes,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> generateNewSummary(String timeframe) async {
    await Future.delayed(const Duration(seconds: 2));
    final summary = DoctorSummary(
      id: const Uuid().v4(),
      userId: MockDatabase.instance.currentUser ?? 'mock_user_123',
      summaryText: 'This is a newly generated mock summary text.',
      profileSnapshot: {'name': 'Mock User'},
      recentSymptomLogs: [],
      recentRecords: [],
      questionsToAsk: [],
      userNotes: timeframe,
      generatedAt: DateTime.now(),
    );
    MockDatabase.instance.doctorSummaries.insert(0, summary);
  }
}

class MockPrivacyRepository {
  Future<PrivacySettings?> getSettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockDatabase.instance.privacySettings;
  }

  Future<void> saveSettings(PrivacySettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    MockDatabase.instance.privacySettings = settings;
  }
}

class MockFamilyRepository {
  Future<List<FamilyMember>> getMembers(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(MockDatabase.instance.familyMembers);
  }

  Future<void> addMember(FamilyMember member) async {
    await Future.delayed(const Duration(seconds: 1));
    MockDatabase.instance.familyMembers.add(member);
  }
}
