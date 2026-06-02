import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/health_record.dart';

class FirebaseRecordRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseRecordRepository(this._firestore, this._storage);

  Map<String, dynamic> _parseDates(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate().toIso8601String();
      }
    });
    return parsed;
  }

  Future<List<HealthRecord>> getRecords(String userId) async {
    final snap = await _firestore
        .collection('healthRecords')
        .doc(userId)
        .collection('records')
        .orderBy('recordDate', descending: true)
        .get();
        
    return snap.docs.map((doc) {
      final data = _parseDates(doc.data());
      data['id'] = doc.id;
      return HealthRecord.fromJson(data);
    }).toList();
  }

  String _getContentType(String filepath) {
    final lower = filepath.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  Future<void> uploadRecord(HealthRecord record, {File? fileToUpload}) async {
    final ref = _firestore.collection('healthRecords').doc(record.userId).collection('records').doc(record.id.isEmpty ? null : record.id);
    String? fileUrl = record.fileUrl;
    String? storagePath = record.storagePath;

    if (fileToUpload != null) {
      final filename = fileToUpload.path.split(RegExp(r'[/\\]')).last;
      storagePath = 'users/${record.userId}/records/$filename';
      final storageRef = _storage.ref().child(storagePath);
      final contentType = _getContentType(filename);
      await storageRef.putFile(
        fileToUpload,
        SettableMetadata(contentType: contentType),
      );
      fileUrl = await storageRef.getDownloadURL();
    }
    
    final recordToSave = record.copyWith(id: ref.id, fileUrl: fileUrl, storagePath: storagePath);
    final json = recordToSave.toJson();
    
    if (json['recordDate'] != null) json['recordDate'] = Timestamp.fromDate(DateTime.parse(json['recordDate']));
    if (json['createdAt'] != null) json['createdAt'] = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    
    await ref.set(json);
  }
}
