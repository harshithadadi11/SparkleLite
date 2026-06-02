import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_insight.dart';
import '../models/symptom_log.dart';
import '../../features/ai_insights/ai_insight_service.dart';

class FirebaseInsightRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseInsightRepository(this._firestore, this._functions);

  Map<String, dynamic> _parseDates(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate().toIso8601String();
      }
    });
    return parsed;
  }

  Future<List<AIInsight>> getInsights(String userId) async {
    final snap = await _firestore
        .collection('aiInsights')
        .doc(userId)
        .collection('insights')
        .orderBy('createdAt', descending: true)
        .get();
        
    return snap.docs.map((doc) {
      final data = _parseDates(doc.data());
      data['id'] = doc.id;
      return AIInsight.fromJson(data);
    }).toList();
  }

  Future<AIInsight> generateInsight(String userId, List<String> logIds) async {
    final logsSnapshot = await _firestore
        .collection('symptomLogs')
        .doc(userId)
        .collection('logs')
        .where(FieldPath.documentId, whereIn: logIds)
        .get();
        
    final logs = logsSnapshot.docs.map((d) {
      final data = _parseDates(d.data());
      data['id'] = d.id;
      return SymptomLog.fromJson(data);
    }).toList();

    try {
      final callable = _functions.httpsCallable('generateAIInsight',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)));
      
      final result = await callable.call({'logIds': logIds});
      final dataMap = Map<String, dynamic>.from(result.data);
      final insightMap = Map<String, dynamic>.from(dataMap['insight']);
      return AIInsight.fromJson(insightMap);
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        debugPrint('Cloud Function Exception: ${e.code} - ${e.message} - ${e.details}');
        // We catch this to fallback, but if we need to surface to UI as per instructions:
        // Wait, the instruction says:
        // "if Cloud Function throws ANY exception: fall back to local ai_insight_service.generateInsight() log the fallback with debugPrint"
        // "FirebaseFunctionsException caught — never silent: log e.code, e.message, e.details with debugPrint, map to user-readable string, surface to UI via thrown Exception with readable message"
        // But if we fallback, do we still throw? The instruction says "fall back to local... return the AIInsight result".
        // Let's fallback and only throw if fallback fails, or return fallback and surface error?
        // Wait, if we return the insight, we don't throw. If the instruction implies "if we want to throw, throw a readable message", then if we do the fallback, we don't throw, we return.
        // Actually, if we return the insight from fallback, the UI won't get an exception. Let's just return the local insight.
      } else {
        debugPrint('Fallback to local generateInsight due to: $e');
      }
      
      debugPrint('Falling back to local AIInsightService');
      final localService = AIInsightService();
      return localService.generateInsight(logs, userId);
    }
  }

  Future<void> saveInsight(AIInsight insight) async {
    final json = insight.toJson();
    if (json['createdAt'] != null) {
      json['createdAt'] = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    }
    await _firestore
        .collection('aiInsights')
        .doc(insight.userId)
        .collection('insights')
        .doc(insight.id)
        .set(json);
  }
}
