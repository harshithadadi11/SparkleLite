import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/privacy_settings.dart';

class FirebasePrivacyRepository {
  final FirebaseFirestore _firestore;

  FirebasePrivacyRepository(this._firestore);

  Future<PrivacySettings?> getSettings(String userId) async {
    final doc = await _firestore.collection('privacySettings').doc(userId).get();
    if (!doc.exists) return null;
    return PrivacySettings.fromJson(doc.data()!);
  }

  Future<void> saveSettings(PrivacySettings settings) async {
    await _firestore.collection('privacySettings').doc(settings.userId).set(
      settings.toJson(),
      SetOptions(merge: true),
    );
  }
}
