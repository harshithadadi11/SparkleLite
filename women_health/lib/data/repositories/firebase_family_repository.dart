import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member.dart';

class FirebaseFamilyRepository {
  final FirebaseFirestore _firestore;

  FirebaseFamilyRepository(this._firestore);

  Map<String, dynamic> _parseDates(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate().toIso8601String();
      }
    });
    return parsed;
  }

  Future<List<FamilyMember>> getMembers(String userId) async {
    final snap = await _firestore
        .collection('familyMembers')
        .doc(userId)
        .collection('members')
        .orderBy('createdAt', descending: true)
        .get();
        
    return snap.docs.map((doc) {
      final data = _parseDates(doc.data());
      data['id'] = doc.id;
      return FamilyMember.fromJson(data);
    }).toList();
  }

  Future<void> addMember(FamilyMember member) async {
    final ref = _firestore.collection('familyMembers').doc(member.userId).collection('members').doc(member.id.isEmpty ? null : member.id);
    
    final memberToSave = member.id.isEmpty ? member.copyWith(id: ref.id) : member;
    
    final json = memberToSave.toJson();
    if (json['createdAt'] != null) json['createdAt'] = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    
    await ref.set(json);
  }
}
