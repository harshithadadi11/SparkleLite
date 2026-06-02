import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symptom_log.dart';

class FirebaseSymptomRepository {
  final FirebaseFirestore _firestore;

  FirebaseSymptomRepository(this._firestore);

  Map<String, dynamic> _parseDates(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate().toIso8601String();
      }
    });
    return parsed;
  }

  Map<String, dynamic> _encodeDates(SymptomLog log) {
    final json = log.toJson();
    if (json['date'] != null) json['date'] = Timestamp.fromDate(DateTime.parse(json['date']));
    if (json['createdAt'] != null) json['createdAt'] = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    if (json['updatedAt'] != null) json['updatedAt'] = Timestamp.fromDate(DateTime.parse(json['updatedAt']));
    return json;
  }

  Future<List<SymptomLog>> getLogs(String userId) async {
    final snap = await _firestore
        .collection('symptomLogs')
        .doc(userId)
        .collection('logs')
        .orderBy('date', descending: true)
        .get()
        .timeout(const Duration(seconds: 10));
        
    return snap.docs.map((doc) {
      final data = _parseDates(doc.data());
      data['id'] = doc.id;
      return SymptomLog.fromJson(data);
    }).toList();
  }

  Future<void> addLog(SymptomLog log) async {
    final ref = _firestore.collection('symptomLogs').doc(log.userId).collection('logs').doc(log.id.isEmpty ? null : log.id);
    
    // Create a copy with the generated ID if needed
    final logToSave = log.id.isEmpty ? log.copyWith(id: ref.id) : log;
    
    await ref.set(_encodeDates(logToSave)).timeout(const Duration(seconds: 10));
  }

  Future<List<SymptomLog>> getRecentLogs(String userId, int limit) async {
    final snap = await _firestore
        .collection('symptomLogs')
        .doc(userId)
        .collection('logs')
        .orderBy('date', descending: true)
        .limit(limit)
        .get()
        .timeout(const Duration(seconds: 10));
        
    return snap.docs.map((doc) {
      final data = _parseDates(doc.data());
      data['id'] = doc.id;
      return SymptomLog.fromJson(data);
    }).toList();
  }

  Future<void> updateLog(SymptomLog log) async {
    final ref = _firestore.collection('symptomLogs').doc(log.userId).collection('logs').doc(log.id);
    await ref.set(_encodeDates(log));
  }

  Future<void> deleteLog(String userId, String id) async {
    await _firestore.collection('symptomLogs').doc(userId).collection('logs').doc(id).delete().timeout(const Duration(seconds: 10));
  }
}
