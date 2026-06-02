import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/doctor_summary.dart';
import '../models/health_profile.dart';
import '../models/symptom_log.dart';
import '../models/health_record.dart';
import '../../features/doctor_summary/data/summary_builder_service.dart';

class FirebaseSummaryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseSummaryRepository(this._firestore, this._functions);

  Map<String, dynamic> _parseDates(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate().toIso8601String();
      }
    });
    return parsed;
  }

  Future<List<DoctorSummary>> getSummaries(String userId) async {
    final snap = await _firestore
        .collection('doctorSummaries')
        .doc(userId)
        .collection('summaries')
        .orderBy('generatedAt', descending: true)
        .get();
        
    return snap.docs.map((doc) {
      final data = _parseDates(doc.data());
      data['id'] = doc.id;
      return DoctorSummary.fromJson(data);
    }).toList();
  }

  Future<DoctorSummary> generateSummary({
    required String userId,
    required List<String> questionsToAsk,
    String? userNotes,
    String? medications,
  }) async {
    // Step 1: Fetch profile
    HealthProfile? profile;
    final profileSnap = await _firestore.collection('profiles').doc(userId).get();
    if (profileSnap.exists) {
      final data = _parseDates(profileSnap.data()!);
      data['id'] = profileSnap.id;
      profile = HealthProfile.fromJson(data);
    }

    // Step 2: Fetch last 5 symptom logs
    final logsSnap = await _firestore.collection('symptomLogs').doc(userId).collection('logs')
        .orderBy('date', descending: true).limit(5).get();
    final logs = logsSnap.docs.map((d) {
      final data = _parseDates(d.data());
      data['id'] = d.id;
      return SymptomLog.fromJson(data);
    }).toList();

    // Step 3: Fetch records from last 30 days where isPrivate == false
    final thirtyDaysAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
    final recordsSnap = await _firestore.collection('healthRecords').doc(userId).collection('records')
        .where('isPrivate', isEqualTo: false)
        .where('recordDate', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .orderBy('recordDate', descending: true)
        .get();
    final records = recordsSnap.docs.map((d) {
      final data = _parseDates(d.data());
      data['id'] = d.id;
      return HealthRecord.fromJson(data);
    }).toList();

    try {
      final callable = _functions.httpsCallable('generateDoctorSummary',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)));
      
      final result = await callable.call({
        'questionsToAsk': questionsToAsk,
        'userNotes': userNotes,
        'medications': medications,
      });
      final dataMap = Map<String, dynamic>.from(result.data);
      final summaryMap = Map<String, dynamic>.from(dataMap['summary']);
      return DoctorSummary.fromJson(summaryMap);
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        debugPrint('Cloud Function Exception: ${e.code} - ${e.message} - ${e.details}');
      } else {
        debugPrint('Fallback to local buildSummaryText due to: $e');
      }
      
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
  }

  Future<void> saveSummary(DoctorSummary summary) async {
    final json = summary.toJson();
    if (json['generatedAt'] != null) {
      json['generatedAt'] = Timestamp.fromDate(DateTime.parse(json['generatedAt']));
    }
    await _firestore
        .collection('doctorSummaries')
        .doc(summary.userId)
        .collection('summaries')
        .doc(summary.id)
        .set(json);
  }
}
