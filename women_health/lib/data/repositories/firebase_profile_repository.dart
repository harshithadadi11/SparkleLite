import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_profile.dart';

class FirebaseProfileRepository {
  final FirebaseFirestore _firestore;

  FirebaseProfileRepository(this._firestore);

  Map<String, dynamic> _parseDates(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate().toIso8601String();
      }
    });
    return parsed;
  }

  Future<HealthProfile?> getProfile(String userId) async {
    final doc = await _firestore.collection('profiles').doc(userId).get();
    if (!doc.exists) return null;
    
    final data = _parseDates(doc.data()!);
    data['userId'] = userId;
    return HealthProfile.fromJson(data);
  }

  Future<void> saveProfile(HealthProfile profile) async {
    final json = profile.toJson();
    if (json['createdAt'] != null) json['createdAt'] = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    if (json['updatedAt'] != null) json['updatedAt'] = Timestamp.fromDate(DateTime.parse(json['updatedAt']));
    
    await _firestore.collection('profiles').doc(profile.userId).set(
      json,
      SetOptions(merge: true),
    );
  }
}
